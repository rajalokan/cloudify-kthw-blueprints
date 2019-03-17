#! /bin/bash -e

ctx logger info "Bootstrapping KTHW dns"

sudo apt install -y wget || sudo yum install -y wget

if [[ ! -f /tmp/sclib.sh ]]; then
    wget -q https://raw.githubusercontent.com/rajalokan/okanstack/master/sclib.sh -O /tmp/sclib.sh
fi
source /tmp/sclib.sh

_preconfigure_instance kthw-dns
ctx logger info "Preconfiguration Done"

# export DNS_EXTERNAL_IP=$(openstack server show dns.${DOMAIN} -f value -c addresses | awk '{ print $2 }')
# ssh -i ~/.ssh/k8s.pem centos@${DNS_EXTERNAL_IP}

CTRL0_IP="192.168.90.26"
CTRL1_IP="192.168.90.29"
CTRL2_IP="192.168.90.30"
WORKER0_IP="192.168.90.4"
WORKER1_IP="192.168.90.6"
WORKER2_IP="192.168.90.20"
LB_IP="192.168.90.22"

export DOMAIN='kthw.lan'
# export UPSTREAM_DNS=$(awk '/nameserver/ { print $2 }' /etc/resolv.conf)
export UPSTREAM_DNS="8.8.8.8; 8.8.4.4"

sudo tee -a /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DNS1=${UPSTREAM_DNS}
PEERDNS=no
EOF

ctx logger info "Installing bind package"

sudo yum install -y firewalld python-firewall bind-utils bind

sudo systemctl enable firewalld --now
sudo firewall-cmd --zone public --add-service dns
sudo firewall-cmd --zone public --add-service dns --permanent

sudo cp /etc/named.conf{,.orig}

ctx logger info "Configuring bind package"

sudo tee /etc/named.conf << EOF
options {
  listen-on port 53 { any; };
  directory "/var/named";
  dump-file "/var/named/data/cache_dump.db";
  statistics-file "/var/named/data/named_stats.txt";
  memstatistics-file "/var/named/data/named_mem_stats.txt";
  allow-query { any; };
  forward only;
  forwarders { ${UPSTREAM_DNS}; };
  managed-keys-directory "/var/named/dynamic";
  pid-file "/run/named/named.pid";
  session-keyfile "/run/named/session.key";
};

logging {
  channel default_debug {
    file "data/named.run";
    severity dynamic;
  };
};

zone "." IN {
  type hint;
  file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
include "/etc/named/zones.conf";
EOF

sudo tee /etc/named/zones.conf << EOF
include "/etc/named/update.key" ;
zone ${DOMAIN} {
  type master ;
  file "/var/named/dynamic/zone.db" ;
  allow-update { key update-key ; } ;
};
EOF

sudo rndc-confgen -a -c /etc/named/update.key -k update-key -r /dev/urandom
sudo chown root.named /etc/named/update.key
sudo chmod 640 /etc/named/update.key

export INTERNAL_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
sudo tee /var/named/dynamic/zone.db << EOF
\$ORIGIN .
\$TTL 300	; 5 minutes
${DOMAIN} IN SOA dns.${DOMAIN}. admin.${DOMAIN}. (
        1          ; serial
        28800      ; refresh (8 hours)
        3600       ; retry (1 hour)
        604800     ; expire (1 week)
        86400      ; minimum (1 day)
        )
        NS dns.${DOMAIN}.
\$ORIGIN ${DOMAIN}.
\$TTL 3600	; 1 hour
dns         A   ${INTERNAL_IP}
ctrl0       A   ${CTRL0_IP}
ctrl1       A   ${CTRL1_IP}
ctrl2       A   ${CTRL2_IP}
worker0     A   ${WORKER0_IP}
worker1     A   ${WORKER1_IP}
worker2     A   ${WORKER2_IP}
EOF

ctx logger info "Verifying named.conf file"
sudo named-checkconf /etc/named.conf
sudo named-checkzone ${DOMAIN} /var/named/dynamic/zone.db

sudo systemctl enable named --now

ctx logger info "Configuration Successful"

# dig @${INTERNAL_IP} ${DOMAIN} axfr
#
# sudo yum clean all
# sudo yum update -y
# # sudo reboot
#
# # DNS_INTERNAL_IP=$(openstack server show dns.${DOMAIN} -f value -c addresses | awk -F'[=,]' '{print $2}')
# # openstack subnet set --dns-nameserver ${DNS_INTERNAL_IP} kubernetes
