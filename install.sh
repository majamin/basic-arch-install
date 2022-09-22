#!/bin/bash

user="marian"
DEVICE="/dev/sda"
REGION="CA"
RAM=2 #GiB

BOOT="${DEVICE}1"
SWAP="${DEVICE}2"
ROOT="${DEVICE}3"
HOME="${DEVICE}4"

umount -l $BOOT &>/dev/null
umount -l $ROOT &>/dev/null
umount -l $HOME &>/dev/null

timedatectl set-ntp true

# Partitions
parted -s -a optimal "$DEVICE" -- mklabel gpt
parted -s -a optimal "$DEVICE" mkpart primary 1MiB 513MiB
parted -s -a optimal "$DEVICE" mkpart primary 514MiB "$((RAM * 2048))"MiB
parted -s -a optimal "$DEVICE" mkpart primary "$(( RAM * 2048 + 1 ))"MiB 40%
parted -s -a optimal "$DEVICE" mkpart primary 40% 100%
parted "$DEVICE" set 1 esp on

# format
mkfs.fat -F32 $BOOT
mkswap $SWAP
swapon
mkfs.ext4 $ROOT
mkfs.ext4 $HOME

# get fast mirrors
#curl -s "https://archlinux.org/mirrorlist/?country=${REGION}&protocol=https&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - > /etc/pacman.d/mirrorlist && pacman -Syy

# mount partitions
mount $ROOT /mnt
mkdir -p /mnt/boot/efi
mount $BOOT /mnt/boot/efi
mkdir /mnt/home
mount $HOME /mnt/home

pacstrap /mnt base linux linux-firmware git vim

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt

ln -sf /usr/share/zoneinfo/Canada/Pacific /etc/localtime
#ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
hwclock --systohc
echo en_US.UTF-8 > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
#echo "KEYMAP=de_CH-latin1" >> /etc/vconsole.conf
echo "arch" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
echo root:password | chpasswd

pacman -S grub efibootmgr networkmanager network-manager-applet dialog wpa_supplicant mtools dosfstools base-devel linux-headers avahi xdg-user-dirs xdg-utils gvfs gvfs-smb nfs-utils inetutils dnsutils bluez bluez-utils cups hplip alsa-utils pipewire pipewire-alsa pipewire-pulse pipewire-jack bash-completion openssh rsync reflector acpi acpi_call tlp virt-manager qemu qemu-arch-extra edk2-ovmf bridge-utils dnsmasq vde2 openbsd-netcat iptables-nft ipset firewalld flatpak sof-firmware nss-mdns acpid os-prober ntfs-3g terminus-font

# pacman -S --noconfirm xf86-video-amdgpu
# pacman -S --noconfirm nvidia nvidia-utils nvidia-settings

grub-install --target=x86_64-efi --efi-directory=$BOOT --bootloader-id=GRUB #change the directory to /boot/efi is you mounted the EFI partition at /boot/efi

grub-mkconfig -o /boot/grub/grub.cfg

systemctl enable NetworkManager
systemctl enable bluetooth
systemctl enable cups.service
systemctl enable sshd
systemctl enable avahi-daemon
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable libvirtd
systemctl enable firewalld
systemctl enable acpid

useradd -m $user
echo $user:password | chpasswd
usermod -aG libvirt $user

echo "$user ALL=(ALL) ALL" >> /etc/sudoers.d/$user

printf "\e[1;32mDone! Your password is 'password'. Type exit, umount -a and reboot.\e[0m"
