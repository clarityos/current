#!/bin/bash
set -euxo pipefail

# -----------------------------
# Environment
# -----------------------------
FEDORA_VERSION=$(rpm -E %fedora)
CLARITY_VERSION="$FEDORA_VERSION"

# -----------------------------
# Repositories (VSCodium)
# -----------------------------
rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
cat <<EOF >/etc/yum.repos.d/vscodium.repo
[gitlab.com_paulcarroty_vscodium_repo]
name=download.vscodium.com
baseurl=https://download.vscodium.com/rpms/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
metadata_expire=1h
EOF

# -----------------------------
# Applications
# -----------------------------
dnf5 -y install codium kvantum materia-kde \
    papirus-icon-theme papirus-icon-theme-dark papirus-icon-theme-light chafa
dnf5 -y remove libreoffice\* kde-games\* kde-education\* plasma-welcome kate || true

# -----------------------------
# Flatpak
# -----------------------------
flatpak remote-delete --force fedora || true
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.brave.Browser

# -----------------------------
# Branding
# -----------------------------
cat > /etc/os-release <<EOF
NAME="ClarityOS"
PRETTY_NAME="ClarityOS Current ($CLARITY_VERSION)"
ID=clarityos
ID_LIKE=fedora
VARIANT="ClarityOS"
VARIANT_ID=clarityos
VERSION_ID="$CLARITY_VERSION"
HOME_URL="https://clarityos.org"
SUPPORT_URL="https://clarityos.org/support"
BUG_REPORT_URL="https://clarityos.org/issues"
EOF

mkdir -p /usr/share/clarityos
cat > /usr/share/clarityos/image-info.json <<EOF
{
  "image-name": "current",
  "image-flavor": "stable",
  "image-vendor": "clarityos",
  "image-ref": "ostree-image-signed:docker://ghcr.io/clarityos/current",
  "image-tag": "latest",
  "image-branch": "stable",
  "base-image-name": "kinoite",
  "fedora-version": "$FEDORA_VERSION",
  "version": "$FEDORA_VERSION.$(date +%Y%m%d)",
  "version-pretty": "ClarityOS Current ($FEDORA_VERSION.$(date +%Y%m%d))"
}
EOF

# -----------------------------
# Graphics / Wallpaper
# -----------------------------
install -Dm644 /ctx/files/clarityos.png /usr/share/pixmaps/clarityos.png
install -Dm644 /ctx/files/wallpaper.jpg /usr/share/wallpapers/clarityos/wallpaper.jpg

# -----------------------------
# User Skeleton
# -----------------------------
rm -rf /etc/skel/*
cp -r /ctx/skel/. /etc/skel/

# -----------------------------
# Plymouth Boot Watermark
# -----------------------------
install -Dm644 /ctx/files/watermark.png /usr/share/plymouth/themes/spinner/watermark.png
plymouth-set-default-theme -R spinner

# -----------------------------
# GRUB Branding
# -----------------------------
mkdir -p /etc/default/grub.d
echo 'GRUB_DISTRIBUTOR="ClarityOS Current"' > /etc/default/grub.d/clarityos.cfg
