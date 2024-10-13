Steps To Create EBS Volume and Attaching it to the instance

Create EBS volume GP2 and atatch it to Instance

lsblk

fdisk /dev/xvdf

n > p > w >

lsblk

mkfs.ext4 /dev/xvdf1

copy UUID Somewhere

mkdir /dockerdata

nano /etc/fstab

Paste Like below

image

mount -a

df -h
