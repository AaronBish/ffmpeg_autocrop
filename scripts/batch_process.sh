#!/bin/bash
set -e

# Default input and output directories
INPUT_DIR=${1:-"./videos/input"}
OUTPUT_DIR=${2:-"./videos/output"}

# Create the Docker image if it doesn't exist
if ! docker image inspect autocrop &>/dev/null; then
    echo "Building Docker image..."
    docker build -t autocrop .
fi

# Process videos
echo "Processing videos from $INPUT_DIR to $OUTPUT_DIR"
docker run --rm -v "$(realpath "$INPUT_DIR"):/videos/input" -v "$(realpath "$OUTPUT_DIR"):/videos/output" autocrop

echo "Processing complete. Cropped videos are in $OUTPUT_DIR" 