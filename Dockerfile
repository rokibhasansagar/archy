# syntax=docker/dockerfile:1-labs
FROM --platform=$BUILDPLATFORM archlinux:base AS rootfs

ARG TARGETPLATFORM
ARG BUILDPLATFORM

SHELL ["/bin/bash", "-c"]

RUN <<-'EOL'
	set -x
	# Initialize pacman keyring
	pacman-key --init && pacman-key --populate archlinux
	# OPTIMIZATION: Prevent installation of man pages and docs
	sed -i.bak 's/#NoExtract  =/NoExtract  = usr\/share\/help\/* usr\/share\/gtk-doc\/* usr\/share\/doc\/* usr\/share\/man\/* usr\/share\/info\/*/' /etc/pacman.conf
	cp -vf /etc/pacman.conf /etc/pacman.opt.conf
	# Update System
	( pacman -Syu --noconfirm 2>/dev/null ) || ( pacman -Syu --noconfirm 2>/dev/null || true )
	# Install core/base-devel
	pacman -S --noconfirm --needed base-devel
	# Add CachyOS Repo
	# pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
	# pacman-key --lsign-key F3B607488DB35A47
	# export cachymirror="https://mirror.cachyos.org/repo/x86_64/cachyos"
	# pacman -U --noconfirm "${cachymirror}/cachyos-keyring-20240331-1-any.pkg.tar.zst" "${cachymirror}/cachyos-mirrorlist-22-1-any.pkg.tar.zst" "${cachymirror}/cachyos-v3-mirrorlist-22-1-any.pkg.tar.zst"
	# echo "" >>/etc/pacman.conf
	# cat >>/etc/pacman.conf <<EOC
	# [cachyos-v3]
	# Include = /etc/pacman.d/cachyos-v3-mirrorlist
	# [cachyos-core-v3]
	# Include = /etc/pacman.d/cachyos-v3-mirrorlist
	# [cachyos-extra-v3]
	# Include = /etc/pacman.d/cachyos-v3-mirrorlist
	# [cachyos]
	# Include = /etc/pacman.d/cachyos-mirrorlist
	# EOC
	# echo "" >>/etc/pacman.conf
	# Make cachyos pacman conf
	echo "" >>/etc/pacman.opt.conf
	cat >>/etc/pacman.opt.conf <<'EOC'
	[cachyos-v3]
	Server = https://cdn77.cachyos.org/repo/$arch_v3/$repo
	Server = https://cdn.cachyos.org/repo/$arch_v3/$repo
	[cachyos]
	Server = https://cdn77.cachyos.org/repo/$arch/$repo
	Server = https://cdn.cachyos.org/repo/$arch/$repo
	EOC
	# Add Chaotic-AUR
	# pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
	# pacman-key --lsign-key 3056513887B78AEB
	# export chaoticmirror="https://cdn-mirror.chaotic.cx/chaotic-aur"
	# pacman -U --noconfirm "${chaoticmirror}/chaotic-keyring.pkg.tar.zst" "${chaoticmirror}/chaotic-mirrorlist.pkg.tar.zst"
	# cat >>/etc/pacman.conf <<EOH
	# [chaotic-aur]
	# Include = /etc/pacman.d/chaotic-mirrorlist
	# EOH
	# echo "" >>/etc/pacman.conf
	# Make chaotic-aur pacman conf
	echo "" >>/etc/pacman.opt.conf
	cat >>/etc/pacman.opt.conf <<'EOX'
	[chaotic-aur]
	Server = https://geo-mirror.chaotic.cx/$repo/$arch
	Server = https://cdn-mirror.chaotic.cx
	EOX
	# Update System
	# ( pacman -Syu --noconfirm 2>/dev/null ) || ( pacman -Syu --noconfirm 2>/dev/null || true )
	# Install yay & paru (pacman helpers)
	pacman -S --noconfirm --needed paru yay --config /etc/pacman.opt.conf
	# Cleanup pacman caches
	rm -rvf /var/lib/pacman/sync/* /var/cache/pacman/pkg/*.pkg.tar.zst* 2>/dev/null
	# Add "app" user with "sudo" access
	useradd -G wheel -m -s /bin/bash app
	echo -e "\n%wheel ALL=(ALL:ALL) NOPASSWD: ALL\napp   ALL=(ALL:ALL) NOPASSWD: ALL\n" | tee -a /etc/sudoers
EOL

FROM scratch

LABEL org.opencontainers.image.description="ArchLinux (with CachyOS + Chaotic-AUR) ->> Personally Optimized Arch-based Distribution"

# Copy rootfs
COPY --from=rootfs / /

# Set the hostname to 'archy'
ENV HOSTNAME=archy

# Set a custom shell prompt
ENV PS1="\[\e[0;32m\]\u@archy\[\e[0m\] \[\e[0;32m\]\w\[\e[0m\]# "

USER app

WORKDIR /tmp

CMD ["/usr/bin/bash"]

