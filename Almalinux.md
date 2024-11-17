# AlmaLinux
Linux deployment practices

## AlamLinux Hyper-V VM

__Installation options:__

1. Use `/boot/efi` with `1gib` size as boot partition
Disable LVM and use __standard partitioning__
2. Now __XFS__ most appropriate to use in VM context for root `/` storage, assign rest of space
- Use nearest NTP pool, for example `ca.ntp.pool.org` or `lt.ntp.pool.org`
- Configure IPv4 network interface and disable IPv6
- Leave `root` user account disabled
- Configure user account as __administrator__
- Use __Minimal Installation__ mode

### Post installation options
Update installed system, enabel `epel` repository and install utilities
```bash
sudo -s
dnf -y update && dnf -y install epel-release && reboot
dnf -y install hyperv* zram-generator nano curl wget htop glibc-all-langpacks
reboot
```
```bash
free -h
```
Disable Dynamic Memory guest service module (log message flooding) using `modprobe.d` or kernel command
```bash
sudo -s
echo "blacklist hv_balloon" > /etc/modprobe.d/blacklist-hv_balloon.conf
dracut -f
reboot
```
```bash
lsmod | grep hv_balloon
```
```bash
sudo -s
nano /etc/default/grub
# GRUB_CMDLINE_LINUX="... hv_balloon.blacklist=1"
grub2-mkconfig -o /boot/grub2/grub.cfg
reboot
```
