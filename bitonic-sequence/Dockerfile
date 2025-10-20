# Development Dockerfile for Zig Bitonic Sequence Project
FROM almalinux:9

#Install required packages
RUN dnf update -y && dnf install -y \
    git \
    wget \
    xz \
    gcc \
    gcc-c++ \
    make \
    glibc-devel \
    && dnf clean all

# Download and install Zig
RUN wget -q https://ziglang.org/builds/zig-x86_64-linux-0.16.0-dev.452+1f7ee99b3.tar.xz \
    && tar -xf zig-x86_64-linux-0.16.0-dev.452+1f7ee99b3.tar.xz \
    && mv zig-x86_64-linux-0.16.0-dev.452+1f7ee99b3 /opt/zig \
    && rm zig-x86_64-linux-0.16.0-dev.452+1f7ee99b3.tar.xz \
    && ln -s /opt/zig/zig /usr/local/bin/zig

# Set working directory
WORKDIR /app

# Set enviroment variables to avoid cache permission issues
ENV ZIG_CACHE_DIR=/tmp/zig-cache
ENV ZIG_GLOBAL_CACHE_DIR=/tmp/zig-global-cache

# Copy build configuration files
COPY build.zig .

# Install zap dendency (this will create build.zig.zon)
RUN zig fetch --save "git+https://github.com/zigzap/zap#v0.11.0"

# Copy source code
COPY src/ ./src/

# Build the application
RUN zig build

# Expose the port
EXPOSE 8080

# Run the built application
CMD ["./zig-out/bin/bitonic-api"]