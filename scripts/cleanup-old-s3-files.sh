#!/bin/bash

# Script to remove files older than a threshold (in days) from an S3 path
# Requirements: AWS CLI must be installed and configured with credentials via environment variables
# Usage: ./cleanup-old-s3-files.sh <s3-path> <days-threshold> [--dry-run]

set -e

# Configuration
S3_PATH="${1:-}"
DAYS_THRESHOLD="${2:-30}"
DRY_RUN=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
    esac
done

# Validate inputs
if [ -z "$S3_PATH" ]; then
    echo "Error: S3 path is required"
    echo "Usage: $0 <s3-path> <days-threshold> [--dry-run]"
    echo "Example: $0 s3://my-bucket/path/to/files 30"
    echo "Example (dry-run): $0 s3://my-bucket/path/to/files 30 --dry-run"
    exit 1
fi

if ! [[ "$DAYS_THRESHOLD" =~ ^[0-9]+$ ]]; then
    echo "Error: Days threshold must be a positive integer"
    exit 1
fi

# # Check AWS credentials
# if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
#     echo "Error: AWS credentials not found in environment variables"
#     echo "Please set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"
#     exit 1
# fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed"
    exit 1
fi

# Calculate cutoff date (seconds since epoch)
CUTOFF_DATE=$(date -v-${DAYS_THRESHOLD}d +%s 2>/dev/null || date -d "${DAYS_THRESHOLD} days ago" +%s)

if [ "$DRY_RUN" = true ]; then
    echo "=== DRY RUN MODE - No files will be deleted ==="
fi

echo "Scanning S3 path: $S3_PATH"
echo "Removing files older than $DAYS_THRESHOLD days"
echo "Cutoff date: $(date -r $CUTOFF_DATE 2>/dev/null || date -d @$CUTOFF_DATE)"
echo ""

# List all files in S3 path and filter by age
DELETED_COUNT=0
TOTAL_SIZE=0

aws s3 ls "$S3_PATH" --recursive | while read -r line; do
    # Parse the line: date time size key
    FILE_DATE=$(echo "$line" | awk '{print $1}')
    FILE_TIME=$(echo "$line" | awk '{print $2}')
    FILE_SIZE=$(echo "$line" | awk '{print $3}')
    FILE_KEY=$(echo "$line" | awk '{$1=$2=$3=""; print $0}' | sed 's/^[ \t]*//')

    # Convert file date to epoch seconds
    FILE_EPOCH=$(date -j -f "%Y-%m-%d %H:%M:%S" "$FILE_DATE $FILE_TIME" +%s 2>/dev/null || date -d "$FILE_DATE $FILE_TIME" +%s)

    # Check if file is older than threshold
    if [ "$FILE_EPOCH" -lt "$CUTOFF_DATE" ]; then
        # Extract bucket and key from S3 path
        BUCKET=$(echo "$S3_PATH" | sed 's|s3://||' | cut -d'/' -f1)
        PREFIX=$(echo "$S3_PATH" | sed 's|s3://||' | cut -d'/' -f2-)

        # Construct full S3 URI
        if [ -z "$PREFIX" ] || [ "$PREFIX" = "$BUCKET" ]; then
            FULL_KEY="s3://$BUCKET/$FILE_KEY"
        else
            FULL_KEY="s3://$BUCKET/$FILE_KEY"
        fi

        if [ "$DRY_RUN" = true ]; then
            echo "[DRY RUN] Would delete: $FULL_KEY (age: $FILE_DATE $FILE_TIME, size: $FILE_SIZE bytes)"
        else
            echo "Deleting: $FULL_KEY (age: $FILE_DATE $FILE_TIME, size: $FILE_SIZE bytes)"
            aws s3 rm "$FULL_KEY"
        fi

        DELETED_COUNT=$((DELETED_COUNT + 1))
        TOTAL_SIZE=$((TOTAL_SIZE + FILE_SIZE))
    fi
done

echo ""
echo "Cleanup complete!"
if [ "$DRY_RUN" = true ]; then
    echo "Files that would be deleted: $DELETED_COUNT"
    echo "Total size that would be freed: $TOTAL_SIZE bytes"
else
    echo "Files deleted: $DELETED_COUNT"
    echo "Total size freed: $TOTAL_SIZE bytes"
fi
