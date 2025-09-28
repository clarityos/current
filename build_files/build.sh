#!/bin/bash
set -euxo pipefail

FEDORA_VERSION=$(rpm -E %fedora)
CLARITY_VERSION="$FEDORA_VERSION"

### -------------------------------------------------------------
### 1️⃣  Repositories
### -------------------------------------------------------------
dnf5 -y copr enable bieszczaders/kernel-cachyos

dnf5 -y install \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm

# Brave Browser
curl -fsSLo /etc/yum.repos.d/brave-browser.repo \
    https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

# VSCodium
rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
printf "[gitlab.com_paulcarroty_vscodium_repo]\n\
name=download.vscodium.com\n\
baseurl=https://download.vscodium.com/rpms/\n\
enabled=1\n\
gpgcheck=1\n\
repo_gpgcheck=1\n\
gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\n\
metadata_expire=1h\n" \
| tee /etc/yum.repos.d/vscodium.repo

### -------------------------------------------------------------
### 2️⃣  Kernel (CI-safe)
### -------------------------------------------------------------
# Fake /dev/log for dracut
mkdir -p /dev
mknod -m 666 /dev/log c 1 3 || true

# Skip kernel-install scripts inside container
export OSTREE_KERNEL_INSTALL_SKIP=1

dnf5 -y install kernel-cachyos kernel-cachyos-devel-matched
dnf5 -y remove kernel kernel-core kernel-modules kernel-modules-core kernel-devel || true

### -------------------------------------------------------------
### 3️⃣  NVIDIA Drivers
### -------------------------------------------------------------
dnf5 -y install akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-power nvidia-vaapi-driver
akmods --force --kernels $(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}\n' kernel-cachyos) || true

### -------------------------------------------------------------
### 4️⃣  Applications
### -------------------------------------------------------------
dnf5 -y install brave-browser codium kvantum materia-kde papirus-icon-thme papirus-icon-theme-dark papirus-icon-theme-light
dnf5 -y remove libreoffice\* kde-games\* kde-education\* plasma-welcome kate || true

update-alternatives --install /usr/bin/x-www-browser x-www-browser /usr/bin/brave-browser-stable 200
update-alternatives --set x-www-browser /usr/bin/brave-browser-stable
xdg-settings set default-web-browser brave-browser.desktop || true

### -------------------------------------------------------------
### 5️⃣  Flatpak
### -------------------------------------------------------------
flatpak remote-delete --if-exists fedora
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

### -------------------------------------------------------------
### 6️⃣  Branding
### -------------------------------------------------------------
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

rpm-ostree compose tree \
    --unified-core \
    --osname=clarityos \
    --version="$CLARITY_VERSION" \
    --releasever="$CLARITY_VERSION" \
    /ctx/treefile.json

### -------------------------------------------------------------
### 7️⃣  Graphics / Wallpaper
### -------------------------------------------------------------
install -Dm644 /ctx/files/clarityos.png /usr/share/pixmaps/clarityos.png
install -Dm644 /ctx/files/wallpaper.jpg /usr/share/wallpapers/clarityos/wallpaper.jpg

### -------------------------------------------------------------
### 8️⃣  User Skeleton
### -------------------------------------------------------------
rm -rf /etc/skel/*
cp -r /ctx/skel/. /etc/skel/

### -------------------------------------------------------------
### 9️⃣  BGRT Boot Logo
### -------------------------------------------------------------
install -Dm644 /ctx/files/clarityos.bmp /usr/share/bootlogos/clarityos.bmp

### -------------------------------------------------------------
### 🔟  Plymouth Boot Watermark
### -------------------------------------------------------------
install -Dm644 /ctx/files/clarityos.png /usr/share/plymouth/themes/spinner/watermark.png

### -------------------------------------------------------------
### 1️⃣1️⃣  Cleanup
### -------------------------------------------------------------
dnf5 clean all
