bootstrap_cfy:
	cfy install openstack.yaml \
		-b kthw \
		-i server_name=kthw

uninstall_cfy:
	cfy uninstall kthw -p ignore_failure=true

output:
	cfy deployment outputs kthw

cancel_install:
	cfy exec cancel `cfy exec li -d kthw | grep "started " | cut -d'|' -f2`

# //////////////////////////////////////////////////////////////////////////////

bootstrap_all: bootstrap_infra bootstrap_dns bootstrap_build bootstrap_lb bootstrap_workers bootstrap_masters

uninstall_all: uninstall_masters uninstall_workers uninstall_lb uninstall_build uninstall_dns uninstall_infra

# //////////////////////////////////////////////////////////////////////////////

bootstrap_infra:
	cfy install openstack_infra.yaml -b kthw-infra

uninstall_infra:
	cfy uninstall kthw-infra -p ignore_failure=true

# //////////////////////////////////////////////////////////////////////////////

bootstrap_dns:
	cfy install openstack_dns.yaml -b kthw-dns

uninstall_dns:
	cfy uninstall kthw-dns -p ignore_failure=true

# //////////////////////////////////////////////////////////////////////////////

bootstrap_build:
	cfy install openstack_build.yaml -b kthw-build

uninstall_build:
	cfy uninstall kthw-build -p ignore_failure=true

# //////////////////////////////////////////////////////////////////////////////

bootstrap_lb:
	cfy install openstack_lb.yaml -b kthw-lb

uninstall_lb:
	cfy uninstall kthw-lb -p ignore_failure=true

# //////////////////////////////////////////////////////////////////////////////

bootstrap_workers:
	cfy install openstack_workers.yaml -b kthw-workers

uninstall_workers:
	cfy uninstall kthw-workers -p ignore_failure=true

# //////////////////////////////////////////////////////////////////////////////

bootstrap_masters:
	cfy install openstack_masters.yaml -b kthw-masters

uninstall_masters:
	cfy uninstall kthw-masters -p ignore_failure=true

# //////////////////////////////////////////////////////////////////////////////
