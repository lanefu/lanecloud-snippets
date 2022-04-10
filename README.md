# lanecloud-snippets
a mess of nomad qemu netbox and more

aka

_how to provision dynamic VMs and config via nomad via ansible_

This is just my opinionated take/attempt at dynamic VM provisioning using a blend of new school and old school tech.

end result is an accelerated VM, configured with IP and DNS record, user keys etc online in under 2 minutes.
## huh?

* cloud-init user-data and meta-data stored as keys in consul KV
* available via nginx rewrite

## why?

I see a lot of the smaller VPS providers using kind of older methods for provisioning and/or just wrappers on proxmox. 
I wanted to see what I could do from scratch using tools I like and be able to tune where I wanted.

### parameterized nomad job

* copy base image to alloc and resize
* configure nocloud ISO with network config and userdata info
* deploy


#### paraam payload

mac address, systemname etc

## ansible

example playbook and template of dynamic dispatch of nomad job for qemu provisioning
