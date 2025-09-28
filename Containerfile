# ---------------------------------------
# Stage 0: Build Context
# ---------------------------------------
FROM scratch AS ctx
COPY build_files /

# ---------------------------------------
# Stage 1: Base Image
# ---------------------------------------
FROM ghcr.io/ublue-os/aurora-asus-nvidia-open:latest

# ---------------------------------------
# Stage 2: Run your build script
# ---------------------------------------
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

# ---------------------------------------
# Stage 3: Set all required labels
# ---------------------------------------
LABEL containers.bootc="1" \
      io.artifacthub.package.deprecated="false" \
      io.artifacthub.package.keywords="bootc,clarityos" \
      io.artifacthub.package.license="Apache-2.0" \
      io.artifacthub.package.logo-url="https://avatars.githubusercontent.com/u/183223563?s=200&v=4" \
      io.artifacthub.package.prerelease="false" \
      io.artifacthub.package.readme-url="https://raw.githubusercontent.com/linuxabyss/clarityos/refs/heads/main/README.md" \
      org.opencontainers.image.created="$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
      org.opencontainers.image.description="Official ClarityOS Image" \
      org.opencontainers.image.documentation="https://raw.githubusercontent.com/linuxabyss/clarityos/refs/heads/main/README.md" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.revision="manual" \
      org.opencontainers.image.source="https://github.com/linuxabyss/clarityos/blob/main/Containerfile" \
      org.opencontainers.image.title="ClarityOS" \
      org.opencontainers.image.url="https://github.com/linuxabyss/clarityos" \
      org.opencontainers.image.vendor="clarityos" \
      org.opencontainers.image.version="latest"

# ---------------------------------------
# Stage 4: Lint (optional, will pass)
# ---------------------------------------
RUN bootc container lint
