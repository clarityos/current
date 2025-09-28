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
# 2️⃣ Applications (excluding Brave RPM)
# -------------------------------------------------------------
dnf5 -y install codium kvantum materia-kde \
    papirus-icon-theme papirus-icon-theme-dark papirus-icon-theme-light
dnf5 -y remove libreoffice\* kde-games\* kde-education\* plasma-welcome kate || true

# -------------------------------------------------------------
# 3️⃣ Flatpak
# -------------------------------------------------------------

# Install Brave via Flatpak
flatpak install -y flathub com.brave.Browser


# -------------------------------------------------------------
# 4️⃣ Branding
# -------------------------------------------------------------
cat > /etc/os-release <<EOF
NAME="ClarityOS"
VERSION="$CLARITY_VERSION"
ID=clarityos
VARIANT="ClarityOS"
VARIANT_ID=clarityos
PRETTY_NAME="ClarityOS $CLARITY_VERSION"
LOGO=clarityos
HOME_URL="https://clarityos.org"
SUPPORT_URL="https://clarityos.org/support"
BUG_REPORT_URL="https://clarityos.org/issues"
EOF

ln -sf /etc/os-release /usr/lib/os-release
dbus-uuidgen --ensure=/etc/machine-id

# Compose OSTree commit
rpm-ostree compose tree \
    --unified-core \
    --osname=clarityos \
    --version="$CLARITY_VERSION" \
    --releasever="$CLARITY_VERSION" \
    /ctx/treefile.json

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
# 8️⃣ Plymouth Boot Watermark
# -------------------------------------------------------------
install -Dm644 /ctx/files/watermark.png /usr/share/plymouth/themes/spinner/watermark.png

# -------------------------------------------------------------
# 9️⃣ Cleanup
# -------------------------------------------------------------
dnf5 clean all
flatpak repair --user
