# Stage 0: Build context
FROM scratch AS ctx
COPY build_files /ctx

# -----------------------------
# Stage 1: Base image
# -----------------------------

FROM quay.io/fedora-ostree-desktops/kinoite:42

# -----------------------------
# Copy build scripts and files
# -----------------------------
COPY --from=ctx /ctx /ctx

# -----------------------------
# Add RPM Fusion repos
# -----------------------------
RUN dnf -y install \
      https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-42.noarch.rpm \
      https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-42.noarch.rpm


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
COPY --from=ghcr.io/ublue-os/akmods-nvidia-open:main-42 / /tmp/akmods-nvidia
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
