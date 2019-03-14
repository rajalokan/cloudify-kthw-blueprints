# cloudify-playbox-blueprints

Cloudify blueprint to install a single or cluster playbox( very simple VM) instance. Currently it only supports OpenStack provider. 

### Note
Before running this blueprint please ensure you have appropriate secrets set up with your openstack credentials. For eg
```
cfy secrets create keystone_username -s <keystone_username>
cfy secrets create keystone_password -s <keystone_password>
cfy secrets create auth_url -s <keystone_auth_url> 
cfy secrets create user_domain_name keystone_user_domain_name -s <keystone_user_domain_name>
cfy secrets create project_name keystone_project_name -s <keystone_project_name>
cfy secrets create project_domain_name -s <keystone_project_domain_name>
cfy secrets create region -s <region>
```

To install a single playbox instance run
```
cfy install \
    https://github.com/rajalokan/cloudify-playbox-blueprints/archive/master.zip \
    --blueprint-filename openstack.yaml \
    --blueprint-id playbox \
    --inputs server_name=playbox
```

To install a three instance playbox cluster run
```
cfy install \
    https://github.com/rajalokan/cloudify-playbox-blueprints/archive/master.zip \
    --blueprint-filename openstack.yaml \
    --blueprint-id playbox_cluster \
    --inputs server_name=playbox \
    --inputs resource_count=3
```
