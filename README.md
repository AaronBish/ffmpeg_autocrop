# Video AutoCrop Docker Container

This Docker container uses FFmpeg to automatically detect and crop black bars from videos while preserving the original video quality. It processes a library of videos and outputs the cropped versions.

## Features

- Automatically detects black bars in videos
- Crops black borders while preserving aspect ratio and video quality
- Processes entire directories of videos
- Skips videos that don't need cropping
- Detailed logging

## Build the Docker Image

```bash
docker build -t autocrop .
```

## Usage

Mount your video directories to the container and run:

```bash
docker run --rm -v /path/to/your/videos:/videos/input -v /path/to/output:/videos/output autocrop
```

### Parameters

- First argument (optional): Input directory (default: `/videos/input`)
- Second argument (optional): Output directory (default: `/videos/output`)

Example with custom directories:

```bash
docker run --rm -v /path/to/your/videos:/custom/input -v /path/to/output:/custom/output autocrop /custom/input /custom/output
```

## Supported Video Formats

- MP4 (.mp4)
- MKV (.mkv)
- AVI (.avi)
- MOV (.mov)
- WMV (.wmv)
- FLV (.flv)

## How It Works

The script uses FFmpeg's cropdetect filter to analyze videos at multiple points (10%, 50%, and 90% of the video duration) to determine the optimal crop parameters. It then applies a crop filter to remove black bars while maintaining the original video quality.

## Included Scripts

### Main Script (`scripts/autocrop.sh`)

This is the main script that processes videos inside the Docker container.

### Batch Processing Script (`scripts/batch_process.sh`)

A helper script to run the Docker container on a directory of videos:

```bash
./scripts/batch_process.sh /path/to/videos /path/to/output
```

### Video Analysis Script (`scripts/analyze_video.sh`)

Analyzes a single video and displays crop information without actually cropping:

```bash
./scripts/analyze_video.sh /path/to/video.mp4
```

This script shows:

- Video information (dimensions, codec, duration)
- Detected crop parameters at different points in the video
- How much of the video would be cropped
- The FFmpeg command needed to crop the video

### Test Script (`scripts/test.sh`)

Creates a sample video with black bars for testing:

```bash
./scripts/test.sh
```

This generates a test video in `/tmp/autocrop_test/input/` and provides instructions on how to process it.

## Logs

Logs are written to `/app/autocrop.log` within the container and also output to the console.

## Examples

### Process a Single Video

```bash
# First create input and output directories
mkdir -p ~/videos/input ~/videos/output

# Copy your video to the input directory
cp movie.mp4 ~/videos/input/

# Run the container
docker run --rm -v ~/videos/input:/videos/input -v ~/videos/output:/videos/output autocrop
```

### Analyze Without Cropping

```bash
./scripts/analyze_video.sh movie.mp4
```

### Batch Process a Folder of Videos

```bash
./scripts/batch_process.sh ~/videos/input ~/videos/output
```
