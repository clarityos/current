# Stage 0: Build context
FROM scratch AS ctx
COPY build_files /ctx

# Stage 1: Base image
ARG FEDORA_VERSION=42
FROM quay.io/fedora-ostree-desktops/kinoite:${FEDORA_VERSION}

# -----------------------------
# Copy build scripts and files
# -----------------------------
COPY --from=ctx /ctx /ctx

# -----------------------------
# Add RPM Fusion for NVIDIA support
# -----------------------------
RUN dnf -y install \
      https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VERSION}.noarch.rpm \
      https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VERSION}.noarch.rpm \
    && dnf clean all

# -----------------------------
# Add CachyOS kernel
# -----------------------------
RUN dnf -y copr enable bieszczaders/kernel-cachyos \
    && dnf -y remove kernel kernel-core kernel-modules kernel-modules-core || true \
    && dnf -y install kernel-cachyos kernel-cachyos-devel-matched \
    && setsebool -P domain_kernel_load_modules on || true

# -----------------------------
# Add NVIDIA akmods
# -----------------------------
COPY --from=ghcr.io/ublue-os/akmods-nvidia-open:main-${FEDORA_VERSION} / /tmp/akmods-nvidia
RUN dnf -y install /tmp/akmods-nvidia/rpms/ublue-os/ublue-os-nvidia*.rpm \
    && dnf -y install /tmp/akmods-nvidia/rpms/kmods/kmod-nvidia*.rpm

# -----------------------------
# Run customization script
# -----------------------------
RUN --mount=type=cache,target=/var/cache \
    --mount=type=cache,target=/var/log \
    --mount=type=tmpfs,target=/tmp \
    /ctx/build.sh

# -----------------------------
# Lint the container for BIB
# -----------------------------
RUN bootc container lint
