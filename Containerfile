# Stage 0: context with build files
FROM scratch AS ctx
COPY build_files /ctx

# Stage 1: base image
FROM ghcr.io/ublue-os/aurora-nvidia-open:latest


# Copy build scripts and files from ctx
COPY --from=ctx /ctx /ctx

# Run customization script
RUN --mount=type=cache,target=/var/cache \
    --mount=type=cache,target=/var/log \
    --mount=type=tmpfs,target=/tmp \
    /ctx/build.sh

# Lint the container for BIB
RUN bootc container lint
