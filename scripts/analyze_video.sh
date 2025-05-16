#!/bin/bash
set -e

# Check if a file was provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 /path/to/video.mp4"
    exit 1
fi

VIDEO_FILE="$1"

# Check if file exists
if [ ! -f "$VIDEO_FILE" ]; then
    echo "Error: File $VIDEO_FILE does not exist"
    exit 1
fi

# Get video information
echo "Video information:"
ffprobe -v error -show_entries format=duration,size -select_streams v:0 -show_entries stream=width,height,codec_name,display_aspect_ratio -of default=noprint_wrappers=1 "$VIDEO_FILE"

# Get video duration
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$VIDEO_FILE")

# Define sample points
pts1=$(echo "$duration * 0.1" | bc)
pts2=$(echo "$duration * 0.5" | bc)
pts3=$(echo "$duration * 0.9" | bc)

# Check for crop at each sample point
echo -e "\nDetecting crop parameters at different points in the video:"
for pts in $pts1 $pts2 $pts3; do
    echo -e "\nAt $(printf "%.2f" $pts) seconds ($(printf "%.1f" $(echo "$pts * 100 / $duration" | bc -l))% of video):"
    ffmpeg -ss "$pts" -i "$VIDEO_FILE" -vframes 10 -vf cropdetect=24:16:0 -f null - 2>&1 | grep -o "crop=.*" | tail -1
done

# Get final crop recommendation
echo -e "\nRecommended crop parameters:"
final_crop=$(ffmpeg -ss "$pts2" -i "$VIDEO_FILE" -vframes 10 -vf cropdetect=24:16:0 -f null - 2>&1 | grep -o "crop=.*" | tail -1)
echo "$final_crop"

# Extract crop dimensions
if [ -n "$final_crop" ]; then
    crop_width=$(echo "$final_crop" | sed -n 's/crop=\([0-9]*\):.*/\1/p')
    crop_height=$(echo "$final_crop" | sed -n 's/crop=[0-9]*:\([0-9]*\):.*/\1/p')
    crop_x=$(echo "$final_crop" | sed -n 's/crop=[0-9]*:[0-9]*:\([0-9]*\):.*/\1/p')
    crop_y=$(echo "$final_crop" | sed -n 's/crop=[0-9]*:[0-9]*:[0-9]*:\([0-9]*\)/\1/p')
    
    # Get original dimensions
    dimensions=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$VIDEO_FILE")
    orig_width=$(echo "$dimensions" | cut -d'x' -f1)
    orig_height=$(echo "$dimensions" | cut -d'x' -f2)
    
    # Calculate how much will be cropped
    width_reduction=$((orig_width - crop_width))
    height_reduction=$((orig_height - crop_height))
    
    echo -e "\nOriginal dimensions: ${orig_width}x${orig_height}"
    echo "Cropped dimensions: ${crop_width}x${crop_height}"
    echo "Pixels cropped: ${width_reduction} width, ${height_reduction} height"
    
    # Calculate percentages
    width_percent=$(echo "scale=2; $width_reduction * 100 / $orig_width" | bc)
    height_percent=$(echo "scale=2; $height_reduction * 100 / $orig_height" | bc)
    
    echo "Percentage cropped: ${width_percent}% width, ${height_percent}% height"
    
    # Show FFmpeg command to crop
    echo -e "\nTo crop this video, run:"
    echo "ffmpeg -i \"$VIDEO_FILE\" -vf \"$final_crop\" -c:v libx264 -crf 18 -preset medium -c:a copy \"${VIDEO_FILE%.*}_cropped.${VIDEO_FILE##*.}\""
else
    echo "No cropping needed"
fi 