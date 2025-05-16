FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install ffmpeg and required dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    xvfb \
    libsdl2-2.0-0 \
    x11-utils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create directory for scripts and videos
WORKDIR /app

# Copy scripts to the container with execute permissions
COPY --chmod=0755 scripts/ /app/scripts/

# Set the entry point to the main script
ENTRYPOINT ["/app/scripts/autocrop.sh"] 