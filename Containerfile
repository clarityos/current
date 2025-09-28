# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM ghcr.io/ublue-os/aurora-asus-nvidia-open:latest

# -------------------------------
# Run your build script
# -------------------------------
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

# -------------------------------
# Set custom image labels for Fastfetch / metadata
# -------------------------------
LABEL org.opencontainers.image.title="ClarityOS"
LABEL org.opencontainers.image.description="Official ClarityOS Image"
LABEL org.opencontainers.image.url="https://github.com/linuxabyss/clarityos"
LABEL org.opencontainers.image.source="https://github.com/linuxabyss/clarityos/blob/main/Containerfile"

# -------------------------------
# Lint the final image
# -------------------------------
RUN bootc container lint

