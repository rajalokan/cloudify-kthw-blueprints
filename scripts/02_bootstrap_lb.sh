#! /bin/bash -e

ctx logger info "Bootstrapping KTHW dns"

sudo apt install -y wget || sudo yum install -y wget

if [[ ! -f /tmp/sclib.sh ]]; then
    wget -q https://raw.githubusercontent.com/rajalokan/okanstack/master/sclib.sh -O /tmp/sclib.sh
fi
source /tmp/sclib.sh

_preconfigure_instance kthw-lb

export DOMAIN='kthw.lan'
sudo yum install -y haproxy

sudo tee /etc/haproxy/haproxy.cfg << EOF
global
    log         127.0.0.1 local2
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     4000
    user        haproxy
    group       haproxy
    daemon
    stats socket /var/lib/haproxy/stats

defaults
    log                     global
    option                  httplog
    option                  dontlognull
    option                  http-server-close
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          1m
    timeout server          1m
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 3000

listen stats :9000
    stats enable
    stats realm Haproxy\ Statistics
    stats uri /haproxy_stats
    stats auth admin:password
    stats refresh 30
    mode http

frontend  main *:6443
    default_backend mgmt6443

backend mgmt6443
    balance source
    mode tcp
    # MASTERS 6443
    server ctrl0.${DOMAIN} ${CTRL0_IP} check
    server ctrl1.${DOMAIN} ${CTRL1_IP} check
    server ctrl2.${DOMAIN} ${CTRL2_IP} check
EOF


sudo semanage port --add --type http_port_t --proto tcp 6443

haproxy -c -V -f /etc/haproxy/haproxy.cfg

sudo systemctl enable haproxy --now
sudo yum clean all
sudo yum update -y
# sudo reboot

# Add load balancer to DNS
export DOMAIN="k8s.lan"
export INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
export LB_INTERNAL_IP=${LB_IP}
sudo nsupdate -k /etc/named/update.key <<EOF
server 192.168.90.27
zone ${DOMAIN}
update add api.k8s.lan 3600 A 192.168.90.22
send
quit
EOF
