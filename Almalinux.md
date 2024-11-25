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
dnf -y update
dnf -y install hyperv* zram-generator
dnf -y install nano curl wget htop
dnf -y install glibc-all-langpacks
```
Check Swap via zram is operating
```bash
free -h
```

Storage optimization can be performed via these two options. Edit `nano /etc/fstan` mount options

```bash
UUID=<your-uuid> /mnt/data ext4 defaults,nobarrier 0 0
```

On AlmaLinux none will be default scheduler when operating as guest.
And disable io scheduler, because in guest OS host manages this: `nano /etc/udev/rules.d/60-io-scheduler.rules`

```bash
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
```

```bash
udevadm control --reload
cat /sys/block/<device>/queue/scheduler
```

## Tips

Install Nginx from original developer repository

```bash
yum install yum-utils
```

Edit repository file: `/etc/yum.repos.d/nginx.repo`

```
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
```

```bash
yum-config-manager --enable nginx-mainline
yum install nginx
```

Install PHP from remi
```bash
dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.rpm
dnf -y install yum-utils
dnf module reset php
dnf module install php:remi-8.3
dnf update && dnf install php-fpm
```

```bash
dnf module switch-to php:remi-8.3
```

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

## firewalld

Source: [Firewall Using firewalld](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-using-firewalld-on-rocky-linux-9)

```bash
firewall-cmd --runtime-to-permanent
firewall-cmd --reload
```

Zones definitions:

- __drop__: The lowest level of trust. All incoming connections are dropped without reply and only outgoing connections are possible.
- __block__: Similar to the above, but instead of dropping connections, incoming requests are rejected with an icmp-host-prohibited or icmp6-adm-prohibited message.
- __public__: Represents public, untrusted networks. You don’t trust other computers but may allow selected incoming connections on a case-by-case basis.
- __external__: External networks in the event that you are using the firewall as your gateway. It is configured for NAT masquerading so that your internal network remains private but reachable.
- __internal__: The other side of the external zone, used for the internal portion of a gateway. The computers are fairly trustworthy and some additional services are available.
- __dmz__: Used for computers located in a DMZ (isolated computers that will not have access to the rest of your network). Only certain incoming connections are allowed.
- __work__: Used for work machines. Trust most of the computers in the network. A few more services might be allowed.
- __home__: A home environment. It generally implies that you trust most of the other computers and that a few more services will be accepted.
- __trusted__: Trust all of the machines in the network. The most open of the available options and should be used sparingly.

```bash
firewall-cmd --get-zones
firewall-cmd --get-default-zone
firewall-cmd --get-active-zones
firewall-cmd --zone=home --change-interface=eth0
firewall-cmd --set-default-zone=home
```

Manage services:

```bash
firewall-cmd --get-services
```

Service difinition file: `/usr/lib/firewalld/services/ssh.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>SSH</short>
  <description>Secure Shell (SSH) is a protocol for logging into and executing commands on remote machines. It provides secure encrypted communications. If you plan on accessing your machine remotely via SSH over a firewalled interface, enable this option. You need the openssh-server package installed for this option to be useful.</description>
  <port protocol="tcp" port="22"/>
</service>
```

```bash
firewall-cmd --zone=public --add-service=http
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --runtime-to-permanent
firewall-cmd --zone=public --list-services --permanent
firewall-cmd --zone=public --add-service=https
firewall-cmd --zone=public --add-service=https --permanent 
```

Manage individual sockets:

```bash
firewall-cmd --zone=public --add-port=5000/tcp
firewall-cmd --zone=public --list-ports
firewall-cmd --zone=public --add-port=4990-4999/udp

firewall-cmd --zone=public --permanent --add-port=5000/tcp
firewall-cmd --zone=public --permanent --add-port=4990-4999/udp
firewall-cmd --zone=public --permanent --list-ports
```

Rich rules:

```bash
rule='rule family="ipv4" source address="192.168.1.100" accept'
firewall-cmd --permanent --add-rich-rule="$rule"

rule='rule family="ipv4" port port="22" protocol="tcp" reject'
firewall-cmd --permanent --add-rich-rule="$rule"

rule='rule family="ipv4" source address="192.168.1.0/24" accept'
firewall-cmd --permanent --add-rich-rule="$rule"

# This logs traffic from 192.168.1.200 with the prefix BLOCKED: before rejecting it.
rule='rule family="ipv4" source address="192.168.1.200" log prefix="BLOCKED:" level="warning" reject'
firewall-cmd --permanent --add-rich-rule="$rule"

rule='rule family="ipv4" source address="192.168.2.50" service name="http" accept'
firewall-cmd --permanent --add-rich-rule="$rule"

rule='rule family="ipv4" source address="192.168.2.50" service name="https" accept'
firewall-cmd --permanent --add-rich-rule="$rule"

rule='rule family="ipv4" source address="192.168.1.0/24" port port="3306" protocol="tcp" interface name="eth0" accept'
firewall-cmd --permanent --add-rich-rule="$rule"

# 10 connections per minute
rule='rule family="ipv4" source address="0.0.0.0/0" service name="ssh" limit value="10/m" accept'
firewall-cmd --permanent --add-rich-rule="$rule"

rule='rule family="ipv4" source address="203.0.113.10" drop'
firewall-cmd --permanent --add-rich-rule="$rule"

# Deleting rule
rule='rule family="ipv4" source address="192.168.1.100" accept'
firewall-cmd --permanent --remove-rich-rule="$rule"
```

## nmcli

`nmcli` is regular network manager for RPM Linux

```bash
lspci | grep -i ethernet

nmcli connection show

nmcli connection modify eth0 ipv4.addresses 192.168.1.100/24
nmcli connection modify eth0 ipv4.gateway 192.168.1.1
nmcli connection modify eth0 ipv4.dns "8.8.8.8"
nmcli connection modify eth0 ipv4.method manual

nmcli connection modify eth0 ipv4.method auto

nmcli connection up eth0
```

In case of secondary adapter, route, address:

```bash
sysctl -w net.ipv4.ip_forward=1
```

## dnf automatic

Install and edit systemd service to run each Monday:
```bash
dnf install -y dnf-automatic
nano /usr/lib/systemd/system/dnf-automatic.timer
```
```bash
OnCalendar=Mon *-*-01..12 10:00
```

Edit `nano /etc/dnf/automatic.conf`
```bash
apply_updates = no > apply_updates = yes
reboot = never > reboot = when-needed
```
Reload services and enable:
```bash
systemctl enable dnf-automatic.timer
systemctl daemon-reload
systemctl start dnf-automatic.timer
```