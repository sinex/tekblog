---
title: Replacing a snapraid disk
tags: [sysadmin, storage, snapraid]
---


## Replace a working disk


* Old disk: `/dev/sdx` mounted at /media/disk/data-07 (SnapRaid data d7)
* New Disk: `/dev/sdy`


# 1. Create partition
```sh
parted --script /dev/sdy -- \
    mklabel gpt \
    mkpart primary 1 -1 \
    align-check optimal 1 \
    print
```


# 2. Format
```sh
mkfs.ext4 -m 2 -T largefile /dev/sdy1
```

Explanation of options:

* `-m 2`           Reserve 2% free space
* `-T largefile`   make 1 inode per 1MB
* `-T largefile4`  make 1 inode per 4MB


# 3. Mount and copy data

```sh
mount /dev/sdy1 /mnt
rsync -vPaHAX /media/disk/data-07/ /mnt/
umount /mnt
```


# 4. Update fstab

```sh
# Disable snapraid
crontab -e

# Unmount old drive
umount /media/disk/data-07

# Get UUID or new partition
blkid /dev/sdy1

# Update fstab
vim /etc/fstab
# - UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx /media/disk/data-07  ext4 defaults,nofail,x-systemd.device-timeout=10s 0 0
# + UUID=yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy /media/disk/data-07  ext4 defaults,nofail,x-systemd.device-timeout=10s 0 0

# Mount new drive
systemctl daemon-reload
systemctl restart local-fs.target

```


## 5. Update SnapRAID / MergerFS

```sh
# Check for differences between new disk and what SnapRAID expects
snapraid diff

# Check the data was copied OK
snapraid check -a -d d7

# Sync, should be fast
snapraid sync

# Check MergerFS has the disk mounted
mergerfs.ctl info

# If not, then add it
mergerfs.ctl add /media/disk/data-07

# Re-enable snapraid
crontab -e

```

