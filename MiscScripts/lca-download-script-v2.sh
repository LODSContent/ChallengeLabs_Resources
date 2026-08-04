###############################
#  Title: File Download & Extract Script (Clean Final Folders)
#  Description: Downloads files from GitHub. If unzip = true, downloads to temp, extracts to
#                final destination folder, then deletes the archive. If unzip = false, downloads
#                to temp first, then moves into place (never partially overwrites a good existing
#                file). Optional skip_if_exists = true skips re-downloading if the destination
#                already has content. Echoes "true" only on full success.
#  Target: Linux lab environment (bash)
#  Template: 5.0
#  Version: <YYYY.MM.DD.hhmm>
###############################

#!/bin/bash

# ─────────────────────────────────────────────
# File download manifest (JSON)
# Each entry:
#   source          = GitHub raw URL
#   destination     = local path:
#                      • If unzip = true  → folder where contents will be extracted
#                      • If unzip = false → full path of the file itself, or a folder path
#                                            (folder path auto-appends source filename)
#   unzip           = true  → extract archive to destination (archive deleted after)
#                     false → save file as-is to destination (no extraction)
#   executable      = true  → run chmod +x on downloaded file (non-unzip entries)
#                     false → leave file mode unchanged
#   skip_if_exists  = true  → skip download entirely if the destination already has content
#                             (file exists for non-zip, folder is non-empty for zip)
#                     false → always download
# ─────────────────────────────────────────────
MANIFEST_JSON='
[
    {
        "source": "https://github.com/LODSContent/ChallengeLabs_Resources/raw/refs/heads/master/LabFiles/CIRL/CIRL-LabFiles-Kali.zip",
        "destination": "/home/labuser",
        "unzip": true,
        "executable": false,
        "skip_if_exists": false
    },
    {
        "source": "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/master/SomeFolder/SomeFile.sh",
        "destination": "/home/labuser/Scripts/SomeFile.sh",
        "unzip": false,
        "executable": true,
        "skip_if_exists": false
    }
]
'

# === CONFIG ===
# Retries are primarily here for lab-boot conditions where networking isn't fully up yet
# by the time this script runs. Delay ramps (5s, 10s, 15s...) up to MAX_RETRY_DELAY_SEC,
# giving a generous overall window for the network stack to come online, while permanent
# HTTP errors (bad path, auth, etc.) skip the remaining retries immediately - see
# is_permanent_http_failure below.
MAX_RETRIES=20
INITIAL_RETRY_DELAY_SEC=5
MAX_RETRY_DELAY_SEC=30
DOWNLOAD_TIMEOUT_SEC=60
TEMP_DIR="/tmp/labdownloads"
LOG_DIR="/var/log/lca"           # Deliberately independent of the file destinations above,
LOG_FILE="$LOG_DIR/lca_status.log"   # so log location stays stable even if those destinations
                                      # change. Falls back to /tmp if this folder can't be used.

# Debug toggle
SCRIPT_DEBUG=false
if [[ "${LAB_VARIABLE_DEBUG,,}" == "yes" || "${LAB_VARIABLE_DEBUG,,}" == "true" ]]; then
    SCRIPT_DEBUG=true
    echo "Debug mode is enabled."
fi

# === STATUS BUFFER / LOGGING ===
# Every status line is (1) appended to an in-memory buffer that gets dumped in a single
# block to stderr at the very end if the run failed, and (2) appended to disk immediately, so
# the log survives even if the script terminates unexpectedly before that final dump. The
# script's stdout contract stays exactly "true" or "false" as the final line (plus live debug
# lines when SCRIPT_DEBUG is on), so the platform's existing parsing of that line is undisturbed.
STATUS_BUFFER=()

if ! mkdir -p "$LOG_DIR" 2>/dev/null || ! touch "$LOG_FILE" 2>/dev/null; then
    LOG_DIR="/tmp"
    LOG_FILE="$LOG_DIR/lca_status.log"
    mkdir -p "$LOG_DIR" 2>/dev/null
    touch "$LOG_FILE" 2>/dev/null
fi

write_status() {
    local message="$1"
    local level="${2:-Info}"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local line="[$timestamp] [$level] $message"

    STATUS_BUFFER+=("$line")

    printf '%s\n' "$line" >> "$LOG_FILE" 2>/dev/null

    if [[ "$SCRIPT_DEBUG" == "true" ]]; then
        echo "$line"
    fi
}

# Returns the Content-Length value from a saved header file, if present
get_content_length() {
    local header_file="$1"
    grep -i '^content-length:' "$header_file" 2>/dev/null | tail -n1 | tr -d '\r' | cut -d':' -f2 | tr -d ' '
}

# 4xx client errors (other than 429 rate-limit) are treated as permanent - retrying is
# pointless for a bad path/auth failure. IMPORTANT: a nonzero curl exit code with this
# function never being reached at all (i.e. no HTTP response was received - DNS not
# resolving, connection refused/timed out - the classic "lab VM's networking isn't fully
# up yet" case) is handled separately in the retry loop below and always retries.
is_permanent_http_failure() {
    local code="$1"
    if [[ "$code" =~ ^[0-9]+$ ]] && [ "$code" -ge 400 ] && [ "$code" -lt 500 ] && [ "$code" -ne 429 ]; then
        return 0
    fi
    return 1
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
SKIPS=$(parse_json_array "$MANIFEST_JSON" "skip_if_exists")

# Load into indexed arrays (process substitution instead of a here-string, since the
# lab platform can be finicky with "<<"-style redirects when scripts are relayed over SSH)
mapfile -t SOURCE_ARRAY      < <(printf '%s\n' "$SOURCES")
mapfile -t DESTINATION_ARRAY < <(printf '%s\n' "$DESTINATIONS")
mapfile -t UNZIP_ARRAY       < <(printf '%s\n' "$UNZIPS")
mapfile -t EXECUTABLE_ARRAY  < <(printf '%s\n' "$EXECUTABLES")
mapfile -t SKIP_ARRAY        < <(printf '%s\n' "$SKIPS")

ITEM_COUNT=${#SOURCE_ARRAY[@]}
OVERALL_SUCCESS=true

write_status "=== LCA run started ==="

# Safety-net cleanup of any orphaned temp files from a prior run that terminated abnormally
if [[ -d "$TEMP_DIR" ]]; then
    find "$TEMP_DIR" -maxdepth 1 -name 'LCA_*' -delete 2>/dev/null
fi
mkdir -p "$TEMP_DIR" 2>/dev/null

# C-style for-loop is used deliberately (rather than a manually-incremented while loop) so
# that "continue" on a skipped/failed item can never accidentally skip the index increment.
for (( i=0; i<ITEM_COUNT; i++ )); do
    SOURCE="${SOURCE_ARRAY[$i]}"
    DESTINATION="${DESTINATION_ARRAY[$i]}"
    SHOULD_UNZIP="${UNZIP_ARRAY[$i]}"
    SHOULD_EXECUTABLE="${EXECUTABLE_ARRAY[$i]}"
    SHOULD_SKIP_IF_EXISTS="${SKIP_ARRAY[$i]}"
    RESOLVED_DESTINATION="$DESTINATION"

    # Strip query string to get clean filename
    FILENAME=$(basename "${SOURCE%%\?*}")

    write_status "--- Processing: $SOURCE ---"

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
        if mkdir -p "$DEST_DIR" 2>/dev/null; then
            write_status "Created folder: $DEST_DIR"
        else
            write_status "Failed to create folder '$DEST_DIR'" "Error"
            OVERALL_SUCCESS=false
            continue
        fi
    fi

    # === skip_if_exists check ===
    if [[ "$SHOULD_SKIP_IF_EXISTS" == "true" ]]; then
        ALREADY_PRESENT=false
        if [[ "$SHOULD_UNZIP" == "true" ]]; then
            if [[ -d "$DEST_DIR" ]] && [[ -n "$(ls -A "$DEST_DIR" 2>/dev/null)" ]]; then
                ALREADY_PRESENT=true
            fi
        else
            if [[ -f "$RESOLVED_DESTINATION" ]]; then
                ALREADY_PRESENT=true
            fi
        fi

        if [[ "$ALREADY_PRESENT" == "true" ]]; then
            write_status "skip_if_exists = true and destination already has content - skipping $SOURCE"
            continue
        fi
    fi

    # === Download to a real temp file first (never write directly to the final path) ===
    TEMP_FILE=$(mktemp --suffix="_${FILENAME}" "$TEMP_DIR/LCA_XXXXXX")

    DOWNLOADED=false
    PERMANENT_FAILURE_CODE=""
    ATTEMPT=0

    while [[ "$DOWNLOADED" == "false" && -z "$PERMANENT_FAILURE_CODE" && "$ATTEMPT" -lt "$MAX_RETRIES" ]]; do
        ATTEMPT=$((ATTEMPT + 1))
        write_status "Downloading [Attempt $ATTEMPT/$MAX_RETRIES]: $SOURCE -> $TEMP_FILE"

        HEADER_FILE=$(mktemp "$TEMP_DIR/LCA_headers_XXXXXX")
        HTTP_CODE=$(curl -sS -L -D "$HEADER_FILE" -o "$TEMP_FILE" -w '%{http_code}' --max-time "$DOWNLOAD_TIMEOUT_SEC" "$SOURCE")
        CURL_EXIT=$?

        if [[ $CURL_EXIT -ne 0 ]]; then
            # No HTTP response was ever received - DNS failure, connection refused, timeout, etc.
            # This is exactly the "lab networking isn't up yet" case, so it always retries.
            write_status "Attempt $ATTEMPT failed - connection/network error (e.g. networking not yet ready), curl exit code $CURL_EXIT" "Warning"
            rm -f "$TEMP_FILE" "$HEADER_FILE"
        elif is_permanent_http_failure "$HTTP_CODE"; then
            PERMANENT_FAILURE_CODE="$HTTP_CODE"
            write_status "Permanent HTTP $HTTP_CODE for $SOURCE - not retrying." "Error"
            rm -f "$TEMP_FILE" "$HEADER_FILE"
        elif [[ "$HTTP_CODE" != 2* ]]; then
            write_status "Attempt $ATTEMPT failed - HTTP $HTTP_CODE" "Warning"
            rm -f "$TEMP_FILE" "$HEADER_FILE"
        else
            ACTUAL_SIZE=$(stat -c%s "$TEMP_FILE" 2>/dev/null || echo 0)
            EXPECTED_SIZE=$(get_content_length "$HEADER_FILE")
            rm -f "$HEADER_FILE"

            if [[ "$ACTUAL_SIZE" -le 0 ]]; then
                write_status "Attempt $ATTEMPT failed - downloaded file is empty" "Warning"
                rm -f "$TEMP_FILE"
            elif [[ -n "$EXPECTED_SIZE" && "$ACTUAL_SIZE" != "$EXPECTED_SIZE" ]]; then
                # Minimal validation: if the server told us the expected size, it must match.
                write_status "Attempt $ATTEMPT failed - size mismatch (expected $EXPECTED_SIZE bytes, got $ACTUAL_SIZE bytes)" "Warning"
                rm -f "$TEMP_FILE"
            else
                DOWNLOADED=true
                write_status "Downloaded successfully ($ACTUAL_SIZE bytes)"
            fi
        fi

        if [[ "$DOWNLOADED" == "false" && -z "$PERMANENT_FAILURE_CODE" && "$ATTEMPT" -lt "$MAX_RETRIES" ]]; then
            RETRY_DELAY=$(( INITIAL_RETRY_DELAY_SEC * ATTEMPT ))
            if [[ "$RETRY_DELAY" -gt "$MAX_RETRY_DELAY_SEC" ]]; then
                RETRY_DELAY=$MAX_RETRY_DELAY_SEC
            fi
            write_status "Waiting $RETRY_DELAY second(s) before retry $((ATTEMPT + 1))/$MAX_RETRIES..."
            sleep "$RETRY_DELAY"
        fi
    done

    if [[ "$DOWNLOADED" == "false" ]]; then
        if [[ -n "$PERMANENT_FAILURE_CODE" ]]; then
            write_status "PERMANENT FAILURE (HTTP $PERMANENT_FAILURE_CODE): $SOURCE" "Error"
        else
            write_status "PERMANENT FAILURE after $MAX_RETRIES attempts: $SOURCE" "Error"
        fi
        OVERALL_SUCCESS=false
        rm -f "$TEMP_FILE"
        continue
    fi

    # ── Extract or move file into place ─────────────────────────────────────
    if [[ "$SHOULD_UNZIP" == "true" ]]; then
        write_status "Extracting $TEMP_FILE -> $DESTINATION"
        if unzip -o "$TEMP_FILE" -d "$DESTINATION" > /dev/null 2>&1; then
            write_status "Extraction successful."
        else
            write_status "Extraction failed for '$FILENAME'." "Error"
            OVERALL_SUCCESS=false
        fi
        rm -f "$TEMP_FILE"
        write_status "Deleted temporary archive."
    else
        if mv "$TEMP_FILE" "$RESOLVED_DESTINATION" 2>/dev/null; then
            write_status "Moved into place: $RESOLVED_DESTINATION"
            if [[ "$SHOULD_EXECUTABLE" == "true" ]]; then
                if chmod +x "$RESOLVED_DESTINATION" 2>/dev/null; then
                    write_status "Applied executable permissions: $RESOLVED_DESTINATION"
                else
                    write_status "Failed to set executable permissions on '$RESOLVED_DESTINATION'." "Error"
                    OVERALL_SUCCESS=false
                fi
            fi
        else
            write_status "Failed to move '$FILENAME' to '$RESOLVED_DESTINATION'." "Error"
            OVERALL_SUCCESS=false
            rm -f "$TEMP_FILE"
        fi
    fi
done

if [[ "$OVERALL_SUCCESS" == "true" ]]; then
    write_status "=== All operations completed successfully. ==="
else
    write_status "=== One or more operations failed. ===" "Error"
fi

# === Final output ===
# The log file already has the full progressive history on disk regardless of outcome.
# On failure, additionally dump the full buffered history to stderr in a single block so
# the platform can capture it; stdout is left undisturbed so its final line is always
# exactly "true" or "false", matching the existing platform contract.
if [[ "$OVERALL_SUCCESS" == "false" ]]; then
    FULL_LOG=$(printf '%s\n' "${STATUS_BUFFER[@]}")
    printf '%s\n' "$FULL_LOG" >&2
fi

echo "$OVERALL_SUCCESS"
