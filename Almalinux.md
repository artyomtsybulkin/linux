# AlmaLinux
Linux deployment practices

## Install Hyper-V VM

__Installation options:__

1. Use `/boot/efi` with `1gib` size as boot partition
Disable LVM and use __standard partitioning__
2. Now __XFS__ most appropriate to use in VM context for root `/` storage, assign rest of space
3. Use nearest NTP pool, for example `ca.ntp.pool.org` or `lt.ntp.pool.org`
4. Configure IPv4 network interface and disable IPv6
5. Leave `root` user account disabled
6. Configure user account as __administrator__
7. Use __Minimal Installation__ mode

__Post installation options__

Update installed system, enabel `epel` repository and install utilities
```bash
sudo -s
dnf -y update
dnf -y install epel-release
dnf -y install hyperv* zram-generator
dnf -y install nano curl wget htop
dnf -y install glibc-all-langpacks
```
Check Swap via zram is operating
```bash
free -h
```

## Tips

Disable __PHP__ information exposure
```bash
sed -i 's/^expose_php = On/expose_php = Off/' /etc/php.ini
systemctl restart nginx php-fpm
```

Disable __Hyper-V Dynamic Memory__ guest service module (log message flooding) using `modprobe.d` or kernel command (_just checked this solution_)
```bash
sudo -s
echo "blacklist hv_balloon" > /etc/modprobe.d/blacklist-hv_balloon.conf
dracut -f
reboot
```
```bash
lsmod | grep hv_balloon
```
Alternative way to add loader kernel option:
```bash
sudo -s
nano /etc/default/grub
# GRUB_CMDLINE_LINUX="... hv_balloon.blacklist=1"
grub2-mkconfig -o /boot/grub2/grub.cfg
reboot
```

