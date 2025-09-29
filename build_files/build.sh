#!/bin/bash
set -euxo pipefail

# -------------------------------------------------------------
# 0️⃣ Environment
# -------------------------------------------------------------
FEDORA_VERSION=$(rpm -E %fedora)
CLARITY_VERSION="$FEDORA_VERSION"

# -------------------------------------------------------------
# 1️⃣ Repositories (VSCodium)
# -------------------------------------------------------------
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

# -------------------------------------------------------------
# 2️⃣ Applications
# -------------------------------------------------------------
dnf5 -y install codium kvantum materia-kde \
    papirus-icon-theme papirus-icon-theme-dark papirus-icon-theme-light
dnf5 -y remove libreoffice\* kde-games\* kde-education\* plasma-welcome kate || true

# -------------------------------------------------------------
# 3️⃣ Flatpak
# -------------------------------------------------------------
flatpak install -y flathub com.brave.Browser

# -------------------------------------------------------------
# 4️⃣ Branding (ClarityOS)
# -------------------------------------------------------------
cat > /etc/os-release <<EOF
NAME="ClarityOS"
PRETTY_NAME="ClarityOS $CLARITY_VERSION"
ID=clarityos
ID_LIKE=fedora
VARIANT="ClarityOS"
VARIANT_ID=clarityos
VERSION_ID="$CLARITY_VERSION"
HOME_URL="https://clarityos.org"
SUPPORT_URL="https://clarityos.org/support"
BUG_REPORT_URL="https://clarityos.org/issues"
EOF

# -------------------------------------------------------------
# 5️⃣ Graphics / Wallpaper
# -------------------------------------------------------------
install -Dm644 /ctx/files/clarityos.png /usr/share/pixmaps/clarityos.png
install -Dm644 /ctx/files/wallpaper.jpg /usr/share/wallpapers/clarityos/wallpaper.jpg

# -------------------------------------------------------------
# 6️⃣ User Skeleton
# -------------------------------------------------------------
rm -rf /etc/skel/*
cp -r /ctx/skel/. /etc/skel/

# -------------------------------------------------------------
# 7️⃣ Plymouth Boot Watermark
# -------------------------------------------------------------
install -Dm644 /ctx/files/watermark.png /usr/share/plymouth/themes/spinner/watermark.png

# -------------------------------------------------------------
# 8️⃣ GRUB branding (informational; BIB will regenerate)
# -------------------------------------------------------------
mkdir -p /etc/default/grub.d/clarityos.cfg
echo 'GRUB_DISTRIBUTOR="ClarityOS"' > /etc/default/grub.d/clarityos.cfg
