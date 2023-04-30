#!/bin/sh

if [ "$(cat /etc/os-release | grep -E '^ID=' | cut -d '=' -f 2)" != "alpine" ]
then
  echo "This script only supports Alpine Linux."
  exit 1
fi

if [ "$(id -u)" -ne 0 ]
then
  echo "This script must be executed with root privileges."
  exit 1
fi

apk update
apk add --no-cache wget curl openssh-server sshpass

cd /etc/ssh
ssh-keygen -A
sshport=22
sed -i.bak '/^#PermitRootLogin/c PermitRootLogin yes' /etc/ssh/sshd_config
sed -i.bak '/^#PasswordAuthentication/c PasswordAuthentication yes' /etc/ssh/sshd_config
sed -i.bak '/^#ListenAddress/c ListenAddress 0.0.0.0' /etc/ssh/sshd_config
sed -i.bak '/^#AddressFamily/c AddressFamily any' /etc/ssh/sshd_config
sed -i.bak "s/^#\?Port.*/Port $sshport/" /etc/ssh/sshd_config
/usr/sbin/sshd

echo root:"$1" | chpasswd root

rm -f "$0"
