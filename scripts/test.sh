#!/bin/bash
set -e

# Create a test directory
mkdir -p /tmp/autocrop_test/input
mkdir -p /tmp/autocrop_test/output

# Create a sample video with black borders
# Generate a test pattern with black bars (16:9 content in a 4:3 container)
ffmpeg -f lavfi -i testsrc=duration=10:size=640x480:rate=30 \
       -vf "pad=640:480:0:60:black" \
       -c:v libx264 -crf 18 \
       /tmp/autocrop_test/input/test_with_bars.mp4 \
       -hide_banner -y

echo "Test video created: /tmp/autocrop_test/input/test_with_bars.mp4"
echo "You can run the container with:"
echo "docker run --rm -v /tmp/autocrop_test/input:/videos/input -v /tmp/autocrop_test/output:/videos/output autocrop" 