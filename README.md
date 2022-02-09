# Fedora KDE
## chroot into system (nvme drive + encrypted /)
Go into live mode and then run:
```
su

# open encrypted partition
cryptsetup open --type luks /dev/nvme0n1p3 crypto_LUKS

# mount root
mount /dev/mapper/crypto_LUKS /mnt/ -t btrfs -o subvol=root

# mount home
mount /dev/mapper/crypto_LUKS /mnt/home -t btrfs -o subvol=home

# mount boot
mount /dev/nvme0n1p2 /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot/efi

# mount special system folders
mount --bind /dev /mnt/dev
mount -t proc /proc /mnt/proc
mount -t sysfs /sys /mnt/sys
mount -t tmpfs tmpfs /mnt/run

# set nameserver
mkdir -p /mnt/run/systemd/resolve/
echo 'nameserver 1.1.1.1' > /mnt/run/systemd/resolve/stub-resolv.conf

# chroot
chroot /mnt
```

## Steam flatpak controller support:
Source: https://github.com/flathub/com.valvesoftware.Steam/issues/8
- Add Steam's udev rules (https://github.com/ValveSoftware/steam-devices/blob/master/60-steam-input.rules) to /etc/udev/rules.d/60-steam-input.rules and then reload udev rules:
```
sudo udevadm control --reload && sudo udevadm trigger
```

- Enable uinput module
Add to /etc/modules-load.d/uinput.conf:
```
uinput
```
