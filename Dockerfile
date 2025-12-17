# syntax=docker/dockerfile:1-labs
FROM --platform=$BUILDPLATFORM archlinux:base

ARG TARGETPLATFORM
ARG BUILDPLATFORM

SHELL ["/bin/bash", "-c"]

RUN <<-'EOL'
	set -x
	# Update System Immediately
	pacman -Syu --noconfirm 2>/dev/null || true
	# Initialize pacman keyring
	pacman-key --init && pacman-key --populate archlinux
	# Add CachyOS Repo
	pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
	pacman-key --lsign-key F3B607488DB35A47
	export cachymirror="https://mirror.cachyos.org/repo/x86_64/cachyos"
	pacman -U --noconfirm "${cachymirror}/cachyos-keyring-20240331-1-any.pkg.tar.zst" "${cachymirror}/cachyos-mirrorlist-22-1-any.pkg.tar.zst" "${cachymirror}/cachyos-v3-mirrorlist-22-1-any.pkg.tar.zst"
	echo "" >>/etc/pacman.conf
	cat >>/etc/pacman.conf <<EOC
	[cachyos-v3]
	Include = /etc/pacman.d/cachyos-v3-mirrorlist
	[cachyos-core-v3]
	Include = /etc/pacman.d/cachyos-v3-mirrorlist
	[cachyos-extra-v3]
	Include = /etc/pacman.d/cachyos-v3-mirrorlist
	[cachyos]
	Include = /etc/pacman.d/cachyos-mirrorlist
	EOC
	echo "" >>/etc/pacman.conf
	# Update System
	( pacman -Syu --noconfirm 2>/dev/null ) || ( pacman -Syu --noconfirm 2>/dev/null || true )
	# Install base-devel
	pacman -S --noconfirm --needed base-devel pacman-contrib pacutils
	# Add Chaotic-AUR
	pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
	pacman-key --lsign-key 3056513887B78AEB
	export chaoticmirror="https://cdn-mirror.chaotic.cx/chaotic-aur"
	pacman -U --noconfirm "${chaoticmirror}/chaotic-keyring.pkg.tar.zst" "${chaoticmirror}/chaotic-mirrorlist.pkg.tar.zst"
	cat >>/etc/pacman.conf <<EOH
	[chaotic-aur]
	Include = /etc/pacman.d/chaotic-mirrorlist
	EOH
	echo "" >>/etc/pacman.conf
	ls -lAog /etc/pacman.d/
	# rankmirrors test
	ls -lAog /etc/pacman.d/cachyos-mirrorlist
	rankmirrors -t -w -v -r cachyos /etc/pacman.d/cachyos-mirrorlist
	ls -lAog /etc/pacman.d/cachyos-mirrorlist
	# Update System
	( pacman -Syu --noconfirm 2>/dev/null ) || ( pacman -Syu --noconfirm 2>/dev/null || true )
	# Install yay & paru (pacman helpers)
	sudo pacman -S --noconfirm --needed chaotic-aur/paru chaotic-aur/yay
	# Cleanup pacman caches
	sudo rm -rvf /var/lib/pacman/sync/* /var/cache/pacman/pkg/*.pkg.tar.zst* 2>/dev/null
	# Add "app" user with "sudo" access
	useradd -G wheel -m -s /bin/bash app
	echo -e "\n%wheel ALL=(ALL:ALL) NOPASSWD: ALL\napp   ALL=(ALL:ALL) NOPASSWD: ALL\n" | tee -a /etc/sudoers
EOL

USER app

WORKDIR /tmp

