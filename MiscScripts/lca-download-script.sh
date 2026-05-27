###############################
#  Title: File download script
#  Description: Enter the source and destinations in the $ManifestJson array 
#  Target: VM
#  Version: 2026.05.04.1717
###############################

#!/bin/bash

# ─────────────────────────────────────────────
# File download manifest (JSON)
# Each entry:
#   source      = GitHub raw URL
#   destination = local path:
#                 • If unzip = true  → folder where contents will be extracted
#                 • If unzip = false → full path of the file itself
#   unzip       = true  → extract archive to destination (archive deleted after)
#                 false → save file as-is to destination (no extraction)
#   executable  = true  → run chmod +x on downloaded file (non-unzip entries)
#                 false → leave file mode unchanged
# ─────────────────────────────────────────────
MANIFEST_JSON='
[
    {
        "source": "https://github.com/LODSContent/ChallengeLabs_Resources/raw/refs/heads/master/LabFiles/CIRL/CIRL-LabFiles-Kali.zip",
        "destination": "/home/labuser",
        "unzip": true,
        "executable": false
    },
    {
        "source": "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/master/SomeFolder/SomeFile.sh",
        "destination": "/home/labuser/Scripts/SomeFile.sh",
        "unzip": false,
        "executable": true
    }
]
'

# Debug toggle
SCRIPT_DEBUG=false
if [[ "${LAB_VARIABLE_DEBUG,,}" == "yes" || "${LAB_VARIABLE_DEBUG,,}" == "true" ]]; then
    SCRIPT_DEBUG=true
    echo "Debug mode is enabled."
fi

debug() {
    if [[ "$SCRIPT_DEBUG" == "true" ]]; then
        echo "$1"
    fi
}

# ─────────────────────────────────────────────
# Parse JSON manifest using grep/sed - no jq required.
# Extracts values from lines matching "key": value pattern.
# Handles both string values ("value") and boolean values (true/false)
# ─────────────────────────────────────────────
parse_json_array() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -E "\"${key}\"[[:space:]]*:[[:space:]]*(\"[^\"]*\"|true|false)" | sed -E "s/.*\"${key}\"[[:space:]]*:[[:space:]]*([^,}]+).*/\1/" | sed 's/"//g'
}

SOURCES=$(parse_json_array "$MANIFEST_JSON" "source")
DESTINATIONS=$(parse_json_array "$MANIFEST_JSON" "destination")
UNZIPS=$(parse_json_array "$MANIFEST_JSON" "unzip")
EXECUTABLES=$(parse_json_array "$MANIFEST_JSON" "executable")

# Load into indexed arrays
mapfile -t SOURCE_ARRAY      <<< "$SOURCES"
mapfile -t DESTINATION_ARRAY <<< "$DESTINATIONS"
mapfile -t UNZIP_ARRAY       <<< "$UNZIPS"
mapfile -t EXECUTABLE_ARRAY  <<< "$EXECUTABLES"

ITEM_COUNT=${#SOURCE_ARRAY[@]}

TEMP_DIR="/tmp/labdownloads"
OVERALL_SUCCESS=true

# Ensure temp directory exists
if [[ ! -d "$TEMP_DIR" ]]; then
    debug "Creating temp directory: $TEMP_DIR"
    mkdir -p "$TEMP_DIR"
fi

i=0
while [ "$i" -lt "$ITEM_COUNT" ]; do
    SOURCE="${SOURCE_ARRAY[$i]}"
    DESTINATION="${DESTINATION_ARRAY[$i]}"
    SHOULD_UNZIP="${UNZIP_ARRAY[$i]}"
    SHOULD_EXECUTABLE="${EXECUTABLE_ARRAY[$i]}"
    RESOLVED_DESTINATION="$DESTINATION"

    # Strip query string to get clean filename
    FILENAME=$(basename "${SOURCE%%\?*}")
    TEMP_FILE="$TEMP_DIR/$FILENAME"

    debug "Processing: $FILENAME"
    debug "  Source:      $SOURCE"
    debug "  Destination: $DESTINATION"
    debug "  Resolved to: $RESOLVED_DESTINATION"
    debug "  Should unzip: $SHOULD_UNZIP"
    debug "  Executable:  $SHOULD_EXECUTABLE"

    # ── Resolve destination and ensure destination directory exists ───────────
    if [[ "$SHOULD_UNZIP" == "true" ]]; then
        DEST_DIR="$DESTINATION"
    else
        DEST_BASENAME=$(basename "$DESTINATION")
        DEST_IS_FOLDER=false

        if [[ -d "$DESTINATION" || "$DESTINATION" == */ ]]; then
            DEST_IS_FOLDER=true
        elif [[ ! -e "$DESTINATION" && "$DEST_BASENAME" != *.* ]]; then
            DEST_IS_FOLDER=true
        fi

        if [[ "$DEST_IS_FOLDER" == "true" ]]; then
            DEST_DIR="${DESTINATION%/}"
            RESOLVED_DESTINATION="$DEST_DIR/$FILENAME"
        else
            DEST_DIR=$(dirname "$DESTINATION")
            RESOLVED_DESTINATION="$DESTINATION"
        fi
    fi

    if [[ ! -d "$DEST_DIR" ]]; then
        debug "  Creating destination directory: $DEST_DIR"
        mkdir -p "$DEST_DIR"
    fi

    # ── Download with retry loop ──────────────────────────────────────────────
    DOWNLOADED=false
    MAX_RETRIES=10
    ATTEMPT=0

    while [[ "$DOWNLOADED" == "false" && "$ATTEMPT" -lt "$MAX_RETRIES" ]]; do
        ATTEMPT=$((ATTEMPT + 1))
        debug "  Download attempt $ATTEMPT of $MAX_RETRIES..."
        sleep 5

        if curl -fsSL "$SOURCE" -o "$TEMP_FILE" 2>/dev/null; then
            if [[ -f "$TEMP_FILE" ]]; then
                DOWNLOADED=true
            fi
        else
            debug "  Attempt $ATTEMPT failed."
        fi
    done

    if [[ "$DOWNLOADED" == "false" ]]; then
        echo "ERROR: Failed to download '$FILENAME' after $MAX_RETRIES attempts. Skipping."
        OVERALL_SUCCESS=false
        continue
    fi

    debug "  Download succeeded: $TEMP_FILE"

    # ── Extract or move file ──────────────────────────────────────────────────
    if [[ "$SHOULD_UNZIP" == "true" ]]; then
        debug "  Extracting to: $DESTINATION"
        if unzip -o "$TEMP_FILE" -d "$DESTINATION" > /dev/null 2>&1; then
            debug "  Extraction complete."
        else
            echo "ERROR: Failed to extract '$FILENAME'."
            OVERALL_SUCCESS=false
        fi
        rm -f "$TEMP_FILE"
        debug "  Cleaned up temp file: $TEMP_FILE"
    else
        debug "  Moving file to: $RESOLVED_DESTINATION"
        if mv "$TEMP_FILE" "$RESOLVED_DESTINATION" 2>/dev/null; then
            debug "  Move complete."
            if [[ "$SHOULD_EXECUTABLE" == "true" ]]; then
                if chmod +x "$RESOLVED_DESTINATION" 2>/dev/null; then
                    debug "  Applied executable permissions: $RESOLVED_DESTINATION"
                else
                    echo "ERROR: Failed to set executable permissions on '$RESOLVED_DESTINATION'."
                    OVERALL_SUCCESS=false
                fi
            fi
        else
            echo "ERROR: Failed to move '$FILENAME' to '$RESOLVED_DESTINATION'."
            OVERALL_SUCCESS=false
            rm -f "$TEMP_FILE"
        fi
    fi
    i=$((i + 1))
done

debug "All items processed. Overall success: $OVERALL_SUCCESS"

echo $OVERALL_SUCCESS
