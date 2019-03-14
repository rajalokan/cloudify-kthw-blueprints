bootstrap:
	cfy install openstack.yaml \
		-b kthw \
		-i server_name=kthw

uninstall:
	cfy uninstall kthw -p ignore_failure=true

output:
	cfy deployment outputs kthw

cancel_install:
	cfy exec cancel `cfy exec li -d kthw | grep "started " | cut -d'|' -f2`
