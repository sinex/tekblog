---
title: Using QEMU Virtual Machine Manager
tags: [virtual-machines, qemu, sysadmin]
---

### Connecting a VM using virt-viewer 

QEMU virtual machines running on a remote host can be connected to directly:

```sh
virt-viewer --connect qemu+ssh://$USER@$HOST:$PORT/system $VM_NAME
```


### Connecting virt-manager to a remote QEMU i

```sh
virt-manager -c "qemu+ssh://$USER@$HOST:$PORT/system?keyfile=$SSH_PRIVATE_KEY"
```



## Links

[libvirt: Connection URIs](https://libvirt.org/uri.html) -- _https://libvirt.org/uri.html_
