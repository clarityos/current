# Stage 0: Build context
FROM scratch AS ctx
COPY build_files /ctx

# Stage 1: Base image
FROM quay.io/fedora-ostree-desktops/kinoite:43

# -----------------------------
# Copy build scripts and files
# -----------------------------
COPY --from=ctx /ctx /ctx

# -----------------------------
# Add RPM Fusion repos
# -----------------------------
RUN dnf -y install \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-43.noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-43.noarch.rpm

# -------------------------------
# Replace stock kernel with CachyOS
# -------------------------------
RUN dnf -y copr enable bieszczaders/kernel-cachyos

RUN dnf -y remove \
         kernel kernel-core kernel-modules kernel-modules-core \
         kernel-devel kernel-headers || true \
    && dnf -y install \
         kernel-cachyos kernel-cachyos-devel-matched \
         linux-firmware dracut \
    && setsebool -P domain_kernel_load_modules on || true

# -----------------------------
# Install NVIDIA akmods after kernel is set
# -----------------------------
COPY --from=ghcr.io/clarityos/kernel-cachyos-nvidia:latest /rpms/kmods/ /tmp/kmods/
RUN dnf -y install /tmp/kmods/*.rpm

# -------------------------------
# Rebuild initramfs with LUKS + NVIDIA support
# -------------------------------
RUN KVER=$(rpm -q --qf "%{VERSION}-%{RELEASE}.%{ARCH}" kernel-cachyos | head -n1) && \
    echo "Building initramfs for $KVER" && \
    dracut --force --kver "$KVER" /boot/initramfs-"$KVER".img

# -----------------------------
# Run build script
# -----------------------------
RUN --mount=type=cache,target=/var/cache \
    --mount=type=cache,target=/var/log \
    --mount=type=tmpfs,target=/tmp \
    /ctx/build.sh

# -----------------------------
# Optional: Lint the container for BIB
# -----------------------------
RUN bootc container lint || true
