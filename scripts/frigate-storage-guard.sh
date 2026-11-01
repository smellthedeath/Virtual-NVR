#!/usr/bin/env bash
# ==============================================================================
# Frigate Automated Storage Guard
# ==============================================================================
# This script monitors the storage mount point where Frigate recordings are kept.
# If disk utilization reaches or exceeds the THRESHOLD (e.g. 90%), it progressively
# deletes the oldest daily recording folders until usage drops below the limit.
# ==============================================================================

set -euo pipefail

# Configurable threshold percentage
THRESHOLD="${STORAGE_THRESHOLD:-90}"
MOUNT_POINT="${STORAGE_MOUNT:-/data/nvr}"
RECORDINGS_DIR="${MOUNT_POINT}/recordings"

CURRENT_USAGE=$(df -P "$MOUNT_POINT" | awk 'NR==2 {gsub("%",""); print $5}')

if [ -z "$CURRENT_USAGE" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Error: Could not determine disk usage for $MOUNT_POINT" >&2
    exit 1
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Storage Guard: current usage is ${CURRENT_USAGE}% (Threshold: ${THRESHOLD}%)"

while [ "$CURRENT_USAGE" -ge "$THRESHOLD" ]; do
    # Locate the oldest daily recordings folder (format: YYYY-MM-DD)
    OLDEST_DAY=$(ls -1d "${RECORDINGS_DIR}"/20[0-9][0-9]-[0-9][0-9]-[0-9][0-9] 2>/dev/null | sort | head -n 1)

    if [ -z "$OLDEST_DAY" ] || [ ! -d "$OLDEST_DAY" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Warning: No more daily recording folders found to purge."
        break
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Purging oldest recordings directory: $OLDEST_DAY (disk was ${CURRENT_USAGE}%)"
    rm -rf "$OLDEST_DAY"

    CURRENT_USAGE=$(df -P "$MOUNT_POINT" | awk 'NR==2 {gsub("%",""); print $5}')
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Usage after purge: ${CURRENT_USAGE}%"
done

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Storage Guard check completed."
