#!/bin/sh

DEVICE="/dev/sda"
REGION="CA"
RAM=8 #GiB

BOOT="${DEVICE}1"
SWAP="${DEVICE}2"
ROOT="${DEVICE}3"
HOME="${DEVICE}4"

timedatectl set-ntp true

# Partitions
parted -s -a optimal "$DEVICE" -- mklabel gpt
parted -s -a optimal "$DEVICE" mkpart primary 1MiB 513MiB
parted -s -a optimal "$DEVICE" mkpart primary 514MiB "$(($RAM * 2048))"MiB
parted -s -a optimal "$DEVICE" mkpart primary "(( $RAM * 2048 + 1 ))"MiB 40%
parted -s -a optimal "$DEVICE" mkpart primary 40% 100%
parted "$DEVICE" set 1 esp on

# format
mkfs.fat -F32 $BOOT
mkswap $SWAP
swapon
mkfs.ext4 $ROOT
mkfs.ext4 $HOME

# get fast mirrors
#curl -s "https://archlinux.org/mirrorlist/?country=${REGION}&protocol=https&use_mirror_status=on" | sed - e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - > /etc/pacman.d/mirrorlist && pacman -Syy

# mount partitions
mount $ROOT /mnt
mkdir -p /mnt/boot/efi
mount $BOOT /mnt/boot/efi
mkdir /mnt/home
mount $HOME /mnt/home
