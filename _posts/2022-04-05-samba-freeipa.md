---
title: FreeIPA authentication for non-domain Samba shares 
tags: [sysadmin, samba, freeipa]
---

_Original Source: [https://bgstack15.wordpress.com/2017/05/10/samba-share-with-freeipa-auth/](https://bgstack15.wordpress.com/2017/05/10/samba-share-with-freeipa-auth/)_ ([Archived](https://web.archive.org/web/20220331111211/https://bgstack15.wordpress.com/2017/05/10/samba-share-with-freeipa-auth/))


# Use FreeIPA Authentication for Samba CIFS Shares for Non-domain Windows Clients

I couldn’t find a singular place on the Internet for a descriptive guide of how to configure samba to use freeipa authentication for cifs shares for non-domain Windows clients.
There are guides out there for freeipa cross-domain trust, so you can share with a domain-joined Windows client, including [https://www.freeipa.org/page/Howto/Integrating_a_Samba_File_Server_With_IPA](https://bgstack15.wordpress.com/2017/05/10/samba-share-with-freeipa-auth/).

This document will show you how to set up Samba 4.4.4 to use FreeIPA 4.4.0 usernames and passwords to allow Windows clients to connect to cifs shares.

### Example environment:

- Freeipa domain is vm.example.com.
- A freeipa master on CentOS7 host1.vm.example.com 192.168.100.10
- A freeipa replica on CentOS7 host2.vm.example.com 192.168.100.11
- Samba server will go on host2.vm.examplecom.
- Windows client is horatio.vm.example.com.


__update 2020-03-03__

With the information shared by Alexander NA below, by changing a few lines in smb.conf, samba 4.9.1 will work with freeipa! You need to comment out these lines:

```conf
#domain master = Yes
#domain logons = Yes
```

I actually filed a bug a while ago in CentOS, but I need to go update it now.
Samba share with freeipa auth


## Install freeipa server (and replica)

You need a working freeipa environment, which is outside the scope of this document. A quick sample installation process is:


```sh
### INSTALL FREEIPA host1.vm.example.com

firewall-cmd --permanent --add-service=freeipa-ldap --add-service=freeipa-ldaps --add-service=ntp --add-service=dns --add-service=dhcp --add-service=kerberos
firewall-cmd --reload

yum install -y ipa-server ipa-client
ipa-server-install -r VM.EXAMPLE.COM -n vm.example.com --mkhomedir --hostname="$( hostname --fqdn )" --admin-password='adminpassword' --ds-password='dspassword'
```

```sh
### INSTALL REPLICA host2.vm.example.com

firewall-cmd --permanent --add-service=freeipa-ldap --add-service=freeipa-ldaps --add-service=ntp --add-service=dns --add-service=dhcp --add-service=kerberos
firewall-cmd --reload

yum install -y ipa-server ipa-client
ipa-client-install --mkhomedir --force-ntpd --enable-dns-updates
ipa-replica-install --setup-ca --mkhomedir
```

## Install samba server

Install the samba packages.

```sh
yum -y install samba samba-client sssd-libwbclient
```

Create the cifs principal for samba on one of the ipa controllers.

```sh
# run on an ipa controller. This principal name is "service/hostname"
ipa service-add cifs/host2.vm.example.com
```

Fetch the keytab to the samba server. In this example, it’s the same as the replica.

```sh
# on samba server
kinit -kt /etc/krb5.keytab
ipa-getkeytab -s host1.vm.example.com -p cifs/host2.vm.example.com -k /etc/samba/samba.keytab

setsebool -P samba_enable_home_dirs on &
```

Reference: [https://www.freeipa.org/page/Howto/Integrating_a_Samba_File_Server_With_IPA](https://bgstack15.wordpress.com/2017/05/10/samba-share-with-freeipa-auth/)


## Install adtrust components

### On the freeipa controller

```sh
yum -y install ipa-server-trust-ad
ipa-adtrust-install --add-sids
```

I recommend running this interactively, as shown above. Let it overwrite your samba config. It will configure it to use the registry, and we will rewrite it to suit the demands here.
The ipa-adtrust-install command generates the records you need to add to dns. They will look like:

```
Add the following service records to your DNS server for DNS zone vm.example.com: 
_ldap._tcp.Default-First-Site-Name._sites.dc._msdcs.vm.example.com. 86400 IN SRV 0 100 389 host2.vm.example.com.
_kerberos._udp.dc._msdcs.vm.example.com. 86400 IN SRV 0 100 88 host2.vm.example.com.
_kerberos._udp.Default-First-Site-Name._sites.dc._msdcs.vm.example.com. 86400 IN SRV 0 100 88 host2.vm.example.com.
_ldap._tcp.dc._msdcs.vm.example.com. 86400 IN SRV 0 100 389 host2.vm.example.com.
_kerberos._tcp.dc._msdcs.vm.example.com. 86400 IN SRV 0 100 88 host2.vm.example.com.
_kerberos._tcp.Default-First-Site-Name._sites.dc._msdcs.vm.example.com. 86400 IN SRV 0 100 88 host2.vm.example.com.
```

I successfully added them just fine by pasting them into my zone file and running `rndc reconfig` or `systemctl restart named`.
The adtrust mechanism adds new attributes to each user and group, specifically ipaNTSecurityIdentifier (the SID) and ipaNTHash. Technically the ipaNTHash can only be generated when the user changes passwords.

Reference: [https://www.redhat.com/archives/freeipa-users/2015-September/msg00052.html](https://bgstack15.wordpress.com/2017/05/10/samba-share-with-freeipa-auth/)


### On the samba server

Install the `ipa-server-trust-ad` package on the samba server. You need this package there to get the ipasam config option in smb.conf.

```sh
yum -y install ipa-server-trust-ad
```

Open the firewall for the ports mentioned in the output of the command. You can use this script.

```sh
tf=/lib/firewalld/services/freeipa-samba.xml
touch "${tf}"; chmod 0644 "${tf}"; chown root:root "${tf}"; restorecon "${tf}"
cat <<EOFXML > "${tf}"
<?xml version="1.0" encoding="utf-8"?>
 <service>
  <short>IPA and Samba</short>
  <description>This service provides the ports required by the ipa-adtrust-install command.</description>
  <port protocol="tcp" port="135"/>
  <port protocol="tcp" port="138"/>
  <port protocol="tcp" port="139"/>
  <port protocol="tcp" port="445"/>
  <port protocol="tcp" port="1024-1300"/>
  <port protocol="udp" port="138"/>
  <port protocol="udp" port="139"/>
  <port protocol="udp" port="389"/>
  <port protocol="udp" port="445"/>
 </service>
EOFXML
systemctl restart firewalld
firewall-cmd --permanent --add-service=freeipa-samba
firewall-cmd --reload
echo done
```

## Allow samba to read passwords

This is the magic part that is so hard to find on the Internet.
You will need to give special permissions to the samba service to read user passwords.

```sh
ipa permission-add "CIFS server can read user passwords" \
   --attrs={ipaNTHash,ipaNTSecurityIdentifier} \
   --type=user --right={read,search,compare} --bindtype=permission
ipa privilege-add "CIFS server privilege"
ipa privilege-add-permission "CIFS server privilege" \
   --permission="CIFS server can read user passwords"
ipa role-add "CIFS server"
ipa role-add-privilege "CIFS server" --privilege="CIFS server privilege"
ipa role-add-member "CIFS server" --services=cifs/host2.vm.example.com
```

Reference: [http://freeipa-users.redhat.narkive.com/ez2uKpFS/authenticate-samba-3-or-4-with-freeipa](https://bgstack15.wordpress.com/2017/05/10/samba-share-with-freeipa-auth/)

### Explanation

If you use ldapsearch with kerberos authentication (after a kinit admin, of course), you can see attributes about users.

```sh
ldapsearch -Y gssapi "(uid=username)"
```

Even if the user has generated a new password since the adtrust installation, even the admin cannot see the ipaNTHash attribute.
To confirm the samba service can read the ipaNTHash, use its keytab and search for that attribute.

```sh
# on the samba server, so host2.vm.example.com
kdestroy -A
kinit -kt /etc/samba/samba.keytab cifs/host2.vm.example.com
ldapsearch -Y gssapi "(ipaNTHash=*)" ipaNTHash
```

## Configure samba to use freeipa auth

When freeipa adjusts the samba config, it will just make it use the registry backend. You can view the equivalent conf file with `testparm`.
Here is a complete /etc/samba/smb.conf:

```conf
[global]
	debug pid = yes
	realm = VM.EXAMPLE.COM
	workgroup = VM
	#domain master = Yes
	ldap group suffix = cn=groups,cn=accounts
	ldap machine suffix = cn=computers,cn=accounts
	ldap ssl = off
	ldap suffix = dc=vm,dc=example,dc=com
	ldap user suffix = cn=users,cn=accounts
	log file = /var/log/samba/log
	max log size = 100000
	#domain logons = Yes
	registry shares = Yes
	disable spoolss = Yes
	dedicated keytab file = FILE:/etc/samba/samba.keytab
	kerberos method = dedicated keytab
	#passdb backend = ipasam:ldapi://%2fvar%2frun%2fslapd-VM-EXAMPLE-COM.socket
	#passdb backend = ldapsam:ldapi://%2fvar%2frun%2fslapd-VM-EXAMPLE-COM.socket
	passdb backend = ipasam:ldap://host2.vm.example.com ldap://host1.vm.example.com
	security = USER
	create krb5 conf = No
	rpc_daemon:lsasd = fork
	rpc_daemon:epmd = fork
	rpc_server:tcpip = yes
	rpc_server:netlogon = external
	rpc_server:samr = external
	rpc_server:lsasd = external
	rpc_server:lsass = external
	rpc_server:lsarpc = external
	rpc_server:epmapper = external
	ldapsam:trusted = yes
	idmap config * : backend = tdb

	ldap admin dn = cn=Directory Manager

[homes]
	comment = Home Directories
	valid users = %S, %D%w%S
	browseable = No
	read only = No
	inherit acls = Yes
```

```sh
chmod 0644 /etc/samba/smb.conf
chown root:root /etc/samba/smb.conf
restorecon /etc/samba/smb.conf
systemctl restart smb.service
```


## Appendices

### Get localsid

Get the local SID

```sh
net getlocalsid
```

### Changing ipa domains

It’s possible that if you change ipa domains, the sssd cache is not cleared and you will have cached information for the old domain which can prevent user authentication from happening. You can just clear the cache directory manually and restart sssd.

```sh
rm -rf /var/lib/sss/db/*
systemctl restart sssd.service
```

Reference: [https://bgstack15.wordpress.com/2017/05/07/freeipa-client-uninstall-and-reinstall/](https://bgstack15.wordpress.com/2017/05/10/samba-share-with-freeipa-auth/)


## References

1.  install samba and kerberize it:
[https://sites.google.com/site/wikirolanddelepper/directory-services/ipa-server-with-samba](https://sites.google.com/site/wikirolanddelepper/directory-services/ipa-server-with-samba)

2. add cifs/servername entry:
[https://www.freeipa.org/page/Howto/Integrating_a_Samba_File_Server_With_IPA](https://www.freeipa.org/page/Howto/Integrating_a_Samba_File_Server_With_IPA)

3. cifs service needs custom privilege to read password:
[http://freeipa-users.redhat.narkive.com/ez2uKpFS/authenticate-samba-3-or-4-with-freeipa](http://freeipa-users.redhat.narkive.com/ez2uKpFS/authenticate-samba-3-or-4-with-freeipa)

4. Each user must generate a new password:
[https://www.redhat.com/archives/freeipa-users/2015-September/msg00052.html](https://www.redhat.com/archives/freeipa-users/2015-September/msg00052.html)

5. Seminal article about freeipa and samba integration:
[https://techslaves.org/2011/08/24/freeipa-and-samba-3-integration/](https://techslaves.org/2011/08/24/freeipa-and-samba-3-integration/)

6. Changing ipa domains:
[https://bgstack15.wordpress.com/2017/05/07/freeipa-client-uninstall-and-reinstall/](https://bgstack15.wordpress.com/2017/05/07/freeipa-client-uninstall-and-reinstall/)
