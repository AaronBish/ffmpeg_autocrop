#!/bin/bash
set -e

# Default input and output directories
INPUT_DIR=${1:-"/videos/input"}
OUTPUT_DIR=${2:-"/videos/output"}
LOG_FILE="/app/autocrop.log"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to detect crop parameters
detect_crop() {
    local input_file="$1"
    local duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$input_file")
    # Sample at 10%, 50%, and 90% of the video duration
    local pts1=$(echo "$duration * 0.1" | bc)
    local pts2=$(echo "$duration * 0.5" | bc)
    local pts3=$(echo "$duration * 0.9" | bc)
    
    # Use cropdetect filter at different points in the video
    local crop_params=""
    for pts in $pts1 $pts2 $pts3; do
        local params=$(ffmpeg -ss "$pts" -i "$input_file" -vframes 10 -vf "cropdetect=24:16:0" -f null - 2>&1 | awk '/crop/ { print $NF }' | tail -1)
        if [ -n "$params" ]; then
            crop_params="$params"
        fi
    done
    
    echo "$crop_params"
}

# Function to check if cropping is needed
is_cropping_needed() {
    local crop_param="$1"
    local input_file="$2"
    
    # Get original video dimensions
    local dimensions=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$input_file")
    local orig_width=$(echo "$dimensions" | cut -d'x' -f1)
    local orig_height=$(echo "$dimensions" | cut -d'x' -f2)
    
    # Extract crop dimensions
    local crop_width=$(echo "$crop_param" | sed -n 's/.*crop=\([0-9]*\):.*/\1/p')
    local crop_height=$(echo "$crop_param" | sed -n 's/.*crop=[0-9]*:\([0-9]*\):.*/\1/p')
    
    # If no cropping is detected or dimensions are the same, no need to crop
    if [ -z "$crop_param" ] || [ "$crop_width" = "$orig_width" -a "$crop_height" = "$orig_height" ]; then
        return 1
    else
        return 0
    fi
}

# Function to process a video file
process_video() {
    local input_file="$1"
    local filename=$(basename "$input_file")
    local output_file="$OUTPUT_DIR/${filename%.*}_autocropped.${filename##*.}"
    
    log "Processing $filename"
    
    # Detect crop parameters
    log "Detecting crop parameters for $filename"
    local crop_params=$(detect_crop "$input_file")
    
    if [ -z "$crop_params" ]; then
        log "No crop parameters detected for $filename, copying original file"
        cp "$input_file" "$output_file"
        return
    fi
    
    log "Detected crop parameters: $crop_params"
    
    # Check if cropping is needed
    if is_cropping_needed "$crop_params" "$input_file"; then
        log "Applying crop filter to $filename"
        # Use the detected crop parameters to process the video
        ffmpeg -i "$input_file" -vf "$crop_params" -c:v libx264 -crf 18 -preset medium -c:a copy "$output_file" -hide_banner -y
        log "Saved cropped video to $output_file"
    else
        log "No cropping needed for $filename, copying original file"
        cp "$input_file" "$output_file"
    fi
}

# Main function to process all videos in the input directory
process_all_videos() {
    log "Starting autocrop process"
    log "Input directory: $INPUT_DIR"
    log "Output directory: $OUTPUT_DIR"
    
    # Check if input directory exists
    if [ ! -d "$INPUT_DIR" ]; then
        log "Error: Input directory does not exist"
        exit 1
    fi
    
    # Find all video files
    VIDEO_FILES=$(find "$INPUT_DIR" -type f -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" -o -name "*.mov" -o -name "*.wmv" -o -name "*.flv")
    
    if [ -z "$VIDEO_FILES" ]; then
        log "No video files found in input directory"
        exit 0
    fi
    
    # Process each video file
    echo "$VIDEO_FILES" | while read -r video_file; do
        process_video "$video_file"
    done
    
    log "Autocrop process completed"
}

# Run the main function
process_all_videos 