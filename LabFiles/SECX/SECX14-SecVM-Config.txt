#!/bin/bash
# Title: Lab14 LCA - SecVM baseline
# Description: Stages Lab14 SecVM artifacts, route, Splunk data, and tool wrappers, including a stable mssqlclient.py command.
# Target: SecVM
# Version: 2026.05.14 - LCA

set -euo pipefail

TARGET_USER="labuser"
TARGET_HOME="/home/${TARGET_USER}"
DOCS_DIR="${TARGET_HOME}/Documents"
OUTDIR="${DOCS_DIR}/OpsSprint"
TI_DIR="${OUTDIR}/ThreatIntel"
STATUS_FILE="${OUTDIR}/SECX14-stage-status.log"
BRIEF_FILE="${OUTDIR}/SECX14-Operations-Brief.txt"
WEB_LOG="${TI_DIR}/SECX14-web-access.log"
PCAP_FILE="${TI_DIR}/SECX14-DVWA-Traffic.pcapng"
TOOL_LOG="/var/log/secx14-tool-usage.log"
SPLUNK_HOME="/opt/splunk"
SPLUNK_BIN="${SPLUNK_HOME}/bin/splunk"
SPLUNK_AUTH="admin:Passw0rd!"
SPLUNK_INDEX="secx14_web"

log() {
    echo "$*" | tee -a "$STATUS_FILE"
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "ERROR: Run this script with sudo." >&2
        exit 1
    fi
}

prepare_dirs() {
    mkdir -p "$TI_DIR"
    : > "$STATUS_FILE"
    chown -R "${TARGET_USER}:${TARGET_USER}" "$OUTDIR"
    chmod -R u+rwX,go+rX "$OUTDIR"
}

write_brief() {
    cat > "$BRIEF_FILE" <<'EOF'
SECX14 Integrated Operations Sprint Brief

Governance control values
- Governance GPO name: SECX14 Operations Governance
- Governance link target: hexelo.com
- Interactive logon message title: Authorized Use Notice
- Interactive logon message text: This system is for authorized use only. Activity may be monitored and recorded.
- Interactive logon setting: Do not display last signed-in = Enabled

Risk prioritization
- High-priority risk finding: SQL-01
- Assessment path: SecVM -> JumpBox relay -> SQL01
- SQL relay endpoint: 192.168.20.99:14330
- SQL assessment account: secxassess / Passw0rd!
- Current risky condition: xp_cmdshell is enabled.

Threat hunt indicators
- Required User-Agent: python-requests/2.31
- Required target URI: /dvwa/vulnerabilities/fi/
- Required suspicious parameter: page=../../../../etc/passwd
- Required successful HTTP status: 200
- Expected suspicious source IP: 192.168.30.10

Containment target
- Target web path: /dvwa/vulnerabilities/fi/
- Intended Apache access control: Require local
EOF
    chown "${TARGET_USER}:${TARGET_USER}" "$BRIEF_FILE"
    log "Created operations brief: $BRIEF_FILE"
}

write_web_log() {
    cat > "$WEB_LOG" <<'EOF'
192.168.30.10 - - [13/May/2026:10:03:12 +0000] "GET /dvwa/vulnerabilities/fi/?page=../../../../etc/passwd HTTP/1.1" 200 612 "-" "python-requests/2.31"
192.168.30.10 - - [13/May/2026:10:03:13 +0000] "GET /dvwa/vulnerabilities/fi/?page=../../../../etc/hosts HTTP/1.1" 200 612 "-" "python-requests/2.31"
192.168.30.10 - - [13/May/2026:10:03:22 +0000] "GET /dvwa/login.php HTTP/1.1" 200 2411 "-" "Mozilla/5.0"
EOF
    chown "${TARGET_USER}:${TARGET_USER}" "$WEB_LOG"
    log "Created web access log: $WEB_LOG"
}

write_pcap_file() {
    /usr/bin/python3 - "$PCAP_FILE" <<'PY'
import socket
import struct
import sys
import time

out = sys.argv[1]

request = (
    b'GET /dvwa/vulnerabilities/fi/?page=../../../../etc/passwd HTTP/1.1\r\n'
    b'Host: 192.168.20.10\r\n'
    b'User-Agent: python-requests/2.31\r\n'
    b'Accept: */*\r\n'
    b'Connection: keep-alive\r\n'
    b'\r\n'
)
response_body = b'root:x:0:0:root:/root:/bin/bash\nwww-data:x:33:33:www-data:/var/www:/usr/sbin/nologin\n'
response = (
    b'HTTP/1.1 200 OK\r\n'
    b'Server: Apache\r\n'
    b'Content-Type: text/plain\r\n'
    b'Content-Length: ' + str(len(response_body)).encode() + b'\r\n'
    b'\r\n' + response_body
)

src_ip = '192.168.30.10'
dst_ip = '192.168.20.10'
src_mac = bytes.fromhex('001122334455')
dst_mac = bytes.fromhex('66778899aabb')

def checksum(data):
    if len(data) % 2:
        data += b'\x00'
    total = 0
    for i in range(0, len(data), 2):
        total += (data[i] << 8) + data[i+1]
    while total > 0xffff:
        total = (total & 0xffff) + (total >> 16)
    return (~total) & 0xffff

def packet(payload, sip, dip, sport, dport, seq, ack, smac, dmac):
    eth = dmac + smac + struct.pack('!H', 0x0800)
    ver_ihl = 0x45
    tos = 0
    ip_len = 20 + 20 + len(payload)
    ident = 0x1234
    flags_frag = 0x4000
    ttl = 64
    proto = 6
    ip_chk = 0
    sip_b = socket.inet_aton(sip)
    dip_b = socket.inet_aton(dip)
    ip_hdr = struct.pack('!BBHHHBBH4s4s', ver_ihl, tos, ip_len, ident, flags_frag, ttl, proto, ip_chk, sip_b, dip_b)
    ip_chk = checksum(ip_hdr)
    ip_hdr = struct.pack('!BBHHHBBH4s4s', ver_ihl, tos, ip_len, ident, flags_frag, ttl, proto, ip_chk, sip_b, dip_b)

    offset = 5 << 4
    flags = 0x18  # PSH ACK
    window = 65535
    tcp_chk = 0
    urgent = 0
    tcp_hdr = struct.pack('!HHLLBBHHH', sport, dport, seq, ack, offset, flags, window, tcp_chk, urgent)
    pseudo = sip_b + dip_b + struct.pack('!BBH', 0, proto, len(tcp_hdr) + len(payload))
    tcp_chk = checksum(pseudo + tcp_hdr + payload)
    tcp_hdr = struct.pack('!HHLLBBHHH', sport, dport, seq, ack, offset, flags, window, tcp_chk, urgent)
    return eth + ip_hdr + tcp_hdr + payload

pkts = []
pkts.append(packet(request, src_ip, dst_ip, 50123, 80, 1, 1, src_mac, dst_mac))
pkts.append(packet(response, dst_ip, src_ip, 80, 50123, 1, 1 + len(request), dst_mac, src_mac))

with open(out, 'wb') as f:
    # Classic pcap. Wireshark opens by magic number even with .pcapng extension.
    f.write(struct.pack('<IHHIIII', 0xa1b2c3d4, 2, 4, 0, 0, 65535, 1))
    base = int(time.time())
    for idx, p in enumerate(pkts):
        f.write(struct.pack('<IIII', base + idx, 0, len(p), len(p)))
        f.write(p)
PY
    chown "${TARGET_USER}:${TARGET_USER}" "$PCAP_FILE"
    chmod 0644 "$PCAP_FILE"
    log "Created packet capture: $PCAP_FILE"
}

reset_previous_artifacts() {
    rm -f \
      "${OUTDIR}/SECX14-suspicious-http.pcapng" \
      "${OUTDIR}/SECX14-saved-detection-validation.txt" \
      "${OUTDIR}/SECX14-baseline-status.txt" \
      "${OUTDIR}/SECX14-containment-validation.txt"
    log "Removed prior SecVM lab artifacts from $OUTDIR"
}

add_route() {
    if command -v ip >/dev/null 2>&1; then
        # Route both DMZ web traffic and JumpBox relay traffic through the pfSense DMZ interface.
        # 192.168.20.10 is DVWA, used for the HTTP marker in Requirement 2.
        # 192.168.20.99 is JumpBox, used for SQL and syslog relay paths.
        ip route replace 192.168.20.10 via 192.168.30.2 || true
        ip route replace 192.168.20.99 via 192.168.30.2 || true
        log "Added or refreshed route to 192.168.20.10 via 192.168.30.2"
        log "Added or refreshed route to 192.168.20.99 via 192.168.30.2"
    fi
}

ensure_python_alias() {
    # Some packaged Impacket example scripts still use '#!/usr/bin/env python'.
    # SecVM commonly only has python3. Create lightweight aliases so both direct
    # and nested helper calls resolve to python3.
    if ! command -v python >/dev/null 2>&1 && [ -x /usr/bin/python3 ]; then
        ln -sf /usr/bin/python3 /usr/local/bin/python || true
    fi

    if [ ! -e /usr/bin/python ] && [ -x /usr/bin/python3 ]; then
        ln -sf /usr/bin/python3 /usr/bin/python || true
    fi
}

find_mssql_client() {
    # Do not consider /usr/local/bin/mssqlclient.py here because this LCA creates that stable shim.
    local candidate

    # If a prior LCA run preserved the packaged script, prefer that copy.
    if [ -f /usr/local/share/secx14/mssqlclient.real.py ]; then
        echo /usr/local/share/secx14/mssqlclient.real.py
        return 0
    fi

    local candidates=(
        "/usr/bin/impacket-mssqlclient"
        "/usr/local/bin/impacket-mssqlclient"
        "/usr/bin/mssqlclient.py"
        "/opt/impacket/examples/mssqlclient.py"
        "/usr/share/impacket/examples/mssqlclient.py"
        "/usr/share/doc/python3-impacket/examples/mssqlclient.py"
    )

    for candidate in "${candidates[@]}"; do
        if [ "$candidate" = "/usr/local/bin/mssqlclient.py" ]; then
            continue
        fi
        if [ -L "$candidate" ]; then
            local resolved
            resolved="$(readlink -f "$candidate" 2>/dev/null || true)"
            if [ "$resolved" = "/usr/local/bin/mssqlclient.py" ]; then
                continue
            fi
        fi
        if [ -f "$candidate" ] || [ -x "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done

    local cmd
    cmd="$(command -v impacket-mssqlclient 2>/dev/null || true)"
    if [ -n "$cmd" ] && [ "$cmd" != "/usr/local/bin/mssqlclient.py" ]; then
        echo "$cmd"
        return 0
    fi

    if /usr/bin/python3 -c 'import impacket.examples.mssqlclient' >/dev/null 2>&1; then
        echo "__PYTHON_IMPACKET_MODULE__"
        return 0
    fi

    return 1
}

attempt_install_impacket() {
    export DEBIAN_FRONTEND=noninteractive

    if ! command -v apt-get >/dev/null 2>&1; then
        log "WARNING: apt-get was not found. Cannot install Impacket automatically."
        return 1
    fi

    log "mssqlclient.py was not found. Attempting to install Impacket tools from apt."
    /usr/bin/apt-get update -o Acquire::ForceIPv4=true -o Acquire::Retries=3 >/dev/null 2>&1 || true

    # Ubuntu commonly provides python3-impacket. Kali may provide impacket-scripts.
    /usr/bin/apt-get install -y -o Acquire::ForceIPv4=true -o Acquire::Retries=3 python3-impacket >/dev/null 2>&1 || \
    /usr/bin/apt-get install -y -o Acquire::ForceIPv4=true -o Acquire::Retries=3 impacket-scripts >/dev/null 2>&1 || \
    return 1

    return 0
}

ensure_mssql_client() {
    local mssql_real=""
    local wrapper="/usr/local/bin/mssqlclient.py"
    local backup_dir="/usr/local/share/secx14"
    local backup_script="${backup_dir}/mssqlclient.real.py"

    mkdir -p "$backup_dir"
    ensure_python_alias

    # Preserve the packaged /usr/bin/mssqlclient.py before replacing it with a stable shim.
    # This avoids shell hash/path issues where an interactive shell keeps calling /usr/bin/mssqlclient.py.
    if [ -f /usr/bin/mssqlclient.py ] && [ ! -L /usr/bin/mssqlclient.py ]; then
        cp /usr/bin/mssqlclient.py "$backup_script" || true
        chmod 0644 "$backup_script" || true
    fi

    rm -f "$wrapper" 2>/dev/null || true

    mssql_real="$(find_mssql_client || true)"

    if [ -z "$mssql_real" ]; then
        attempt_install_impacket
        # If apt created /usr/bin/mssqlclient.py, preserve it now.
        if [ -f /usr/bin/mssqlclient.py ] && [ ! -L /usr/bin/mssqlclient.py ] && [ ! -f "$backup_script" ]; then
            cp /usr/bin/mssqlclient.py "$backup_script" || true
            chmod 0644 "$backup_script" || true
        fi
        mssql_real="$(find_mssql_client || true)"
    fi

    if [ -z "$mssql_real" ]; then
        log "ERROR: mssqlclient.py or impacket-mssqlclient was not found on SecVM."
        log "Install or stage Impacket on SecVM before this lab runs. The final LCA should not depend on learner action for this tool."
        return 1
    fi

    if [ "$mssql_real" = "__PYTHON_IMPACKET_MODULE__" ]; then
        cat > "$wrapper" <<EOF
#!/bin/bash
hash -r 2>/dev/null || true
echo "\$(date -u +%FT%TZ)|MSSQLCLIENT|\$*" >> "$TOOL_LOG"
exec /usr/bin/python3 -m impacket.examples.mssqlclient "\$@"
EOF
    elif [ -f "$mssql_real" ] && [ "${mssql_real##*.}" = "py" ]; then
        # Run Python scripts with python3 explicitly. This avoids the packaged
        # '#!/usr/bin/env python' failure on systems without a python binary.
        cat > "$wrapper" <<EOF
#!/bin/bash
hash -r 2>/dev/null || true
echo "\$(date -u +%FT%TZ)|MSSQLCLIENT|\$*" >> "$TOOL_LOG"
exec /usr/bin/python3 "$mssql_real" "\$@"
EOF
    elif [ -x "$mssql_real" ]; then
        cat > "$wrapper" <<EOF
#!/bin/bash
hash -r 2>/dev/null || true
echo "\$(date -u +%FT%TZ)|MSSQLCLIENT|\$*" >> "$TOOL_LOG"
exec "$mssql_real" "\$@"
EOF
    else
        cat > "$wrapper" <<EOF
#!/bin/bash
hash -r 2>/dev/null || true
echo "\$(date -u +%FT%TZ)|MSSQLCLIENT|\$*" >> "$TOOL_LOG"
exec /usr/bin/python3 "$mssql_real" "\$@"
EOF
    fi

    chmod +x "$wrapper"

    # Also replace /usr/bin/mssqlclient.py with a symlink to the wrapper. This
    # prevents cached shell paths or /usr/bin-first environments from reaching
    # the older script that calls /usr/bin/env python.
    ln -sf "$wrapper" /usr/bin/mssqlclient.py || true

    log "Initialized mssqlclient.py usage wrapper using ${mssql_real}."
    log "Stable mssqlclient.py path: $wrapper"
}

prepare_tool_wrappers() {
    : > "$TOOL_LOG"
    chown "${TARGET_USER}:${TARGET_USER}" "$TOOL_LOG" 2>/dev/null || true
    chmod 0664 "$TOOL_LOG" 2>/dev/null || true

    if [ -x /usr/bin/nmap ]; then
        cat > /usr/local/bin/nmap <<EOF
#!/bin/bash
echo "\$(date -u +%FT%TZ)|NMAP|\$*" >> "$TOOL_LOG"
exec /usr/bin/nmap "\$@"
EOF
        chmod +x /usr/local/bin/nmap
        log "Initialized nmap usage wrapper."
    else
        log "WARNING: nmap was not found on SecVM. Requirement 1 Nmap validation will fail until nmap is available."
    fi

    ensure_mssql_client
}

find_splunk_deb() {
    find "$TARGET_HOME/Downloads" "/root/Downloads" -maxdepth 1 -type f -iname 'splunk-*.deb' 2>/dev/null | head -n 1
}

splunk_search_works() {
    if [ ! -x "$SPLUNK_BIN" ]; then
        return 1
    fi

    "$SPLUNK_BIN" status >/dev/null 2>&1 ||         "$SPLUNK_BIN" start --accept-license --answer-yes --no-prompt --run-as-root >/dev/null 2>&1 || true

    sleep 5

    local output
    output="$($SPLUNK_BIN search '| makeresults | stats count' -auth "$SPLUNK_AUTH" -maxout 1 2>&1 || true)"

    if printf '%s\n' "$output" | grep -Eiq 'license expired|exceeded your license limit|license violation|Error in .litsearch.|cannot run searches'; then
        return 1
    fi

    if printf '%s\n' "$output" | grep -Eiq 'Login failed|Authentication failed|username|password'; then
        return 1
    fi

    if printf '%s\n' "$output" | grep -Eiq 'count'; then
        return 0
    fi

    # Be conservative. If the search output is not clearly valid, rebuild Splunk.
    return 1
}

install_fresh_splunk() {
    local deb
    deb="$(find_splunk_deb || true)"

    if [ -z "$deb" ]; then
        log "ERROR: Splunk is not usable and no splunk-*.deb installer was found in $TARGET_HOME/Downloads or /root/Downloads."
        return 1
    fi

    log "Reinstalling Splunk from $deb to reset the local trial/license state."

    if [ -x "$SPLUNK_BIN" ]; then
        "$SPLUNK_BIN" stop >/dev/null 2>&1 || true
    fi

    systemctl stop Splunkd >/dev/null 2>&1 || true
    systemctl stop splunk >/dev/null 2>&1 || true

    dpkg -r splunk >/dev/null 2>&1 || true
    rm -rf "$SPLUNK_HOME"

    dpkg -i "$deb" >/dev/null 2>&1 || {
        log "ERROR: dpkg install failed for $deb."
        return 1
    }

    mkdir -p "$SPLUNK_HOME/etc/system/local"
    cat > "$SPLUNK_HOME/etc/system/local/user-seed.conf" <<EOF
[user_info]
USERNAME = admin
PASSWORD = Passw0rd!
EOF

    "$SPLUNK_BIN" start --accept-license --answer-yes --no-prompt --run-as-root >/dev/null 2>&1 || {
        log "ERROR: Splunk did not start after reinstall."
        return 1
    }

    sleep 8
    log "Splunk reinstall and first start completed."
}

ensure_splunk_ready() {
    # Lab14 depends on Splunk search in Requirement 3. The base SecVM image can have
    # Splunk installed but in an expired/stale license state. Do not trust an existing
    # install just because the CLI exists. If the local installer is present, always
    # rebuild Splunk so each fresh lab run gets a usable trial/license state.
    local deb
    deb="$(find_splunk_deb || true)"

    if [ -n "$deb" ]; then
        log "Local Splunk installer found at $deb. Forcing a Splunk reinstall to reset the trial/license state."
        install_fresh_splunk

        if ! splunk_search_works; then
            log "ERROR: Splunk search is still not usable after reinstall."
            return 1
        fi

        log "Splunk is usable after forced reinstall."
        return 0
    fi

    # Fallback only when the installer is not present.
    if splunk_search_works; then
        log "Splunk installer was not found, but the existing Splunk instance appears usable."
        return 0
    fi

    log "ERROR: Splunk search is not usable and no local splunk-*.deb installer was found."
    return 1
}

seed_splunk() {
    ensure_splunk_ready

    "$SPLUNK_BIN" add index "$SPLUNK_INDEX" -auth "$SPLUNK_AUTH" >/dev/null 2>&1 || true

    "$SPLUNK_BIN" add oneshot "$WEB_LOG" -index "$SPLUNK_INDEX" -sourcetype access_combined -auth "$SPLUNK_AUTH" >/dev/null 2>&1 || {
        log "ERROR: Splunk oneshot ingest failed. Review Splunk status before Requirement 3."
        return 1
    }

    log "Seeded Splunk index $SPLUNK_INDEX with $WEB_LOG"
}

main() {
    require_root
    prepare_dirs
    log "Starting SECX14 SecVM LCA baseline."
    reset_previous_artifacts
    add_route
    write_brief
    write_web_log
    write_pcap_file
    prepare_tool_wrappers
    seed_splunk
    chown -R "${TARGET_USER}:${TARGET_USER}" "$OUTDIR"
    log "SECX14 SecVM LCA baseline complete."
    log "Artifacts:"
    log "- $BRIEF_FILE"
    log "- $PCAP_FILE"
    log "- $WEB_LOG"
}

main "$@"
