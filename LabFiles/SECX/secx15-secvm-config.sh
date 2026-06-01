#!/bin/bash
# Title: Lab15 LCA - SecVM operations baseline
# Description: Stages SECX15 operations artifacts, routes, packet capture, Splunk data, and resets the SecVM auth forwarding gap.
# Target: SecVM
# Version: 2026.05.29-v4 - LCA

set -euo pipefail

LAB_USER="labuser"
USER_HOME="/home/${LAB_USER}"
DOCS="${USER_HOME}/Documents"
OPS_DIR="${DOCS}/Operations"
STATUS_FILE="${OPS_DIR}/SECX15-stage-status.log"
BRIEF_FILE="${OPS_DIR}/SECX15-Operations-Brief.txt"
WEB_LOG="${OPS_DIR}/SECX15-web-access.log"
PCAP_FILE="${OPS_DIR}/SECX15-Incident-Traffic.pcapng"
SPLUNK_HOME="/opt/splunk"
SPLUNK_BIN="${SPLUNK_HOME}/bin/splunk"
SPLUNK_AUTH="admin:Passw0rd!"
SPLUNK_INDEX="secx15_web"

log() {
    echo "$*" | tee -a "$STATUS_FILE"
}

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "ERROR: Run this LCA as root." >&2
        exit 1
    fi
}

prepare_dirs() {
    mkdir -p "$OPS_DIR"
    : > "$STATUS_FILE"
    chown -R "${LAB_USER}:${LAB_USER}" "$OPS_DIR"
    chmod -R u+rwX,go+rX "$OPS_DIR"
}

reset_secvm_gap() {
    rm -f /etc/rsyslog.d/secx15-secvm-auth-forwarding.conf
    rm -f /var/lib/rsyslog/imfile-state:* 2>/dev/null || true

    if systemctl list-unit-files 2>/dev/null | grep -q '^rsyslog.service'; then
        systemctl restart rsyslog || true
    fi

    log "Reset SecVM auth forwarding gap."
}

add_routes() {
    if command -v ip >/dev/null 2>&1; then
        ip route replace 192.168.20.0/24 via 192.168.30.2 || true
        ip route replace 192.168.10.0/24 via 192.168.30.2 || true
        log "Added or refreshed routes to 192.168.20.0/24 and 192.168.10.0/24 via 192.168.30.2."
    fi
}

write_brief() {
    cat > "$BRIEF_FILE" <<'BRIEF'
SECX15 Operations Brief

Integrated Sprint Objectives
- Preserve the approved JumpBox administrative entry point and remove the unnecessary Kerberos relay.
- Remove excessive AD privilege and unsafe delegation.
- Harden endpoint visibility on Admin1.
- Reduce unnecessary DVWA exposure and move SRV01 to trusted HTTPS-only service access.
- Close the missing SecVM auth.log coverage gap in centralized logging.

Suspicious Activity
- Source IP: 192.168.30.10
- User-Agent: python-requests/2.31
- Target Path: /dvwa/vulnerabilities/fi/
- Suspicious Parameter: page=../../../../etc/passwd

Monitoring Gap
- SecVM auth.log is not currently reaching the central collector.

Expected Investigation Outcome
- Use the staged packet capture and indexed web telemetry to confirm the suspicious file inclusion probing.
- Save a reusable Splunk hunt named SECX15 Suspicious DVWA Hunt.
- Contain /dvwa/vulnerabilities/fi/ and automate the containment action.
BRIEF

    chown "${LAB_USER}:${LAB_USER}" "$BRIEF_FILE"
    chmod 0644 "$BRIEF_FILE"
    log "Created operations brief: $BRIEF_FILE"
}

write_web_log() {
    cat > "$WEB_LOG" <<'WEBLOG'
192.168.30.10 - - [21/Apr/2026:13:03:12 +0000] "GET /dvwa/vulnerabilities/fi/?page=../../../../etc/passwd HTTP/1.1" 200 712 "-" "python-requests/2.31"
192.168.30.10 - - [21/Apr/2026:13:03:13 +0000] "GET /dvwa/vulnerabilities/fi/ HTTP/1.1" 200 532 "-" "python-requests/2.31"
192.168.30.10 - - [21/Apr/2026:13:03:17 +0000] "GET /dvwa/login.php HTTP/1.1" 200 1432 "-" "Mozilla/5.0"
192.168.30.11 - - [21/Apr/2026:13:03:20 +0000] "GET /dvwa/vulnerabilities/fi/ HTTP/1.1" 200 532 "-" "Mozilla/5.0"
WEBLOG

    chown "${LAB_USER}:${LAB_USER}" "$WEB_LOG"
    chmod 0644 "$WEB_LOG"
    log "Created web access log: $WEB_LOG"
}

append_current_splunk_seed_line() {
    # Append one current line after the Splunk monitor input is configured. This reliably
    # triggers the monitor input even if Splunk has already seen the file during testing.
    printf '192.168.30.10 - - [%s] "GET /dvwa/vulnerabilities/fi/?page=../../../../etc/passwd HTTP/1.1" 200 712 "-" "python-requests/2.31"\n' \
        "$(date -u '+%d/%b/%Y:%H:%M:%S +0000')" >> "$WEB_LOG"
    chown "${LAB_USER}:${LAB_USER}" "$WEB_LOG"
    chmod 0644 "$WEB_LOG"
}

write_pcap_file() {
    /usr/bin/python3 - "$PCAP_FILE" <<'PY'
import socket
import struct
import sys
import time

out = sys.argv[1]
request1 = (
    b'GET /dvwa/vulnerabilities/fi/?page=../../../../etc/passwd HTTP/1.1\r\n'
    b'Host: 192.168.20.10\r\n'
    b'User-Agent: python-requests/2.31\r\n'
    b'Accept: */*\r\n'
    b'Connection: keep-alive\r\n'
    b'\r\n'
)
request2 = (
    b'GET /dvwa/vulnerabilities/fi/ HTTP/1.1\r\n'
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
    ip_len = 20 + 20 + len(payload)
    ident = 0x4321
    flags_frag = 0x4000
    ttl = 64
    proto = 6
    sip_b = socket.inet_aton(sip)
    dip_b = socket.inet_aton(dip)
    ip_hdr = struct.pack('!BBHHHBBH4s4s', ver_ihl, 0, ip_len, ident, flags_frag, ttl, proto, 0, sip_b, dip_b)
    ip_chk = checksum(ip_hdr)
    ip_hdr = struct.pack('!BBHHHBBH4s4s', ver_ihl, 0, ip_len, ident, flags_frag, ttl, proto, ip_chk, sip_b, dip_b)
    tcp_hdr = struct.pack('!HHLLBBHHH', sport, dport, seq, ack, 5 << 4, 0x18, 65535, 0, 0)
    pseudo = sip_b + dip_b + struct.pack('!BBH', 0, proto, len(tcp_hdr) + len(payload))
    tcp_chk = checksum(pseudo + tcp_hdr + payload)
    tcp_hdr = struct.pack('!HHLLBBHHH', sport, dport, seq, ack, 5 << 4, 0x18, 65535, tcp_chk, 0)
    return eth + ip_hdr + tcp_hdr + payload

pkts = [
    packet(request1, src_ip, dst_ip, 50123, 80, 1, 1, src_mac, dst_mac),
    packet(response, dst_ip, src_ip, 80, 50123, 1, 1 + len(request1), dst_mac, src_mac),
    packet(request2, src_ip, dst_ip, 50124, 80, 1, 1, src_mac, dst_mac),
]

with open(out, 'wb') as f:
    # Classic pcap. Wireshark opens by magic number even with a .pcapng extension.
    f.write(struct.pack('<IHHIIII', 0xa1b2c3d4, 2, 4, 0, 0, 65535, 1))
    base = int(time.time())
    for idx, pkt in enumerate(pkts):
        f.write(struct.pack('<IIII', base + idx, 0, len(pkt), len(pkt)))
        f.write(pkt)
PY

    chown "${LAB_USER}:${LAB_USER}" "$PCAP_FILE"
    chmod 0644 "$PCAP_FILE"
    log "Created packet capture: $PCAP_FILE"
}

find_splunk_deb() {
    find "$USER_HOME/Downloads" "/root/Downloads" -maxdepth 1 -type f -iname 'splunk-*.deb' 2>/dev/null | head -n 1
}

wait_for_splunk() {
    local output=""

    for attempt in $(seq 1 60); do
        if [ ! -x "$SPLUNK_BIN" ]; then
            sleep 2
            continue
        fi

        "$SPLUNK_BIN" status >/dev/null 2>&1 || \
            "$SPLUNK_BIN" start --accept-license --answer-yes --no-prompt --run-as-root >/dev/null 2>&1 || true

        output="$($SPLUNK_BIN search '| makeresults | stats count' -auth "$SPLUNK_AUTH" -maxout 1 2>&1 || true)"

        if printf '%s\n' "$output" | grep -q 'count'; then
            return 0
        fi

        if printf '%s\n' "$output" | grep -Eiq 'license expired|exceeded your license limit|license violation|Error in .litsearch.|Login failed|Authentication failed'; then
            return 1
        fi

        sleep 3
    done

    log "ERROR: Splunk did not become searchable. Last output:"
    printf '%s\n' "$output" | tail -n 20 | tee -a "$STATUS_FILE"
    return 1
}

install_fresh_splunk() {
    local deb
    deb="$(find_splunk_deb || true)"

    if [ -z "$deb" ]; then
        log "ERROR: No splunk-*.deb installer was found in Downloads."
        return 1
    fi

    log "Reinstalling Splunk from local installer: $deb"

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
    cat > "$SPLUNK_HOME/etc/system/local/user-seed.conf" <<'SEED'
[user_info]
USERNAME = admin
PASSWORD = Passw0rd!
SEED

    "$SPLUNK_BIN" start --accept-license --answer-yes --no-prompt --run-as-root >/dev/null 2>&1 || {
        log "ERROR: Splunk did not start after reinstall."
        return 1
    }

    wait_for_splunk || {
        log "ERROR: Splunk CLI search is not usable after reinstall."
        return 1
    }

    log "Splunk reinstall complete and CLI search is usable."
}

ensure_splunk_ready() {
    local deb
    deb="$(find_splunk_deb || true)"

    if [ -n "$deb" ]; then
        # Always reset from the local installer when present. This avoids stale trial/license
        # state that can still exist even when Splunk appears installed and running.
        install_fresh_splunk
        return 0
    fi

    if [ ! -x "$SPLUNK_BIN" ]; then
        log "ERROR: Splunk is not installed and no local installer was found."
        return 1
    fi

    "$SPLUNK_BIN" start --accept-license --answer-yes --no-prompt --run-as-root >/dev/null 2>&1 || true
    wait_for_splunk || return 1
    log "Splunk is installed, running, and CLI search is usable."
}

ensure_index() {
    local list_output=""

    list_output="$($SPLUNK_BIN list index -auth "$SPLUNK_AUTH" 2>/dev/null || true)"

    if printf '%s\n' "$list_output" | grep -Fxq "$SPLUNK_INDEX"; then
        log "Splunk index $SPLUNK_INDEX already exists."
        return 0
    fi

    log "Creating Splunk index $SPLUNK_INDEX."
    "$SPLUNK_BIN" add index "$SPLUNK_INDEX" -auth "$SPLUNK_AUTH" >/dev/null 2>&1 || {
        log "ERROR: Failed to create Splunk index $SPLUNK_INDEX."
        return 1
    }

    "$SPLUNK_BIN" restart >/dev/null 2>&1 || true
    wait_for_splunk || return 1
}

seed_splunk_event_rest() {
    local event_line
    local receiver_url
    local curl_output

    event_line="192.168.30.10 - - [$(date -u '+%d/%b/%Y:%H:%M:%S +0000')] \"GET /dvwa/vulnerabilities/fi/?page=../../../../etc/passwd HTTP/1.1\" 200 712 \"-\" \"python-requests/2.31\""

    printf '%s\n' "$event_line" >> "$WEB_LOG"
    chown "${LAB_USER}:${LAB_USER}" "$WEB_LOG"
    chmod 0644 "$WEB_LOG"

    receiver_url="https://127.0.0.1:8089/services/receivers/simple?index=${SPLUNK_INDEX}&sourcetype=access_combined&source=SECX15-web-access.log"

    log "Posting staged SECX15 web event directly to Splunk receiver."
    local response_file
    local http_code
    response_file="$(mktemp)"
    http_code="$(/usr/bin/curl -ksS -u "$SPLUNK_AUTH" --data-binary "$event_line" -o "$response_file" -w '%{http_code}' "$receiver_url" 2>/tmp/secx15_splunk_receiver_curl.err || true)"

    if [ "$http_code" != "200" ] && [ "$http_code" != "201" ]; then
        log "ERROR: Splunk receiver returned HTTP $http_code."
        cat /tmp/secx15_splunk_receiver_curl.err 2>/dev/null | tail -n 20 | tee -a "$STATUS_FILE" || true
        cat "$response_file" 2>/dev/null | tail -n 20 | tee -a "$STATUS_FILE" || true
        rm -f "$response_file"
        return 1
    fi

    rm -f "$response_file"
}

wait_for_secx15_event() {
    local search_output=""
    local ready=0

    for attempt in $(seq 1 120); do
        search_output="$($SPLUNK_BIN search 'search index=secx15_web "python-requests/2.31" "/dvwa/vulnerabilities/fi/" "etc/passwd" | head 5' -earliest_time 0 -latest_time now -auth "$SPLUNK_AUTH" -maxout 10 2>&1 || true)"

        if printf '%s\n' "$search_output" | grep -q 'python-requests/2.31'; then
            ready=1
            break
        fi

        if printf '%s\n' "$search_output" | grep -Eiq 'license expired|exceeded your license limit|license violation|Error in .litsearch.|Login failed|Authentication failed'; then
            log "ERROR: Splunk search reported a license or authentication problem after reset."
            printf '%s\n' "$search_output" | tail -n 20 | tee -a "$STATUS_FILE"
            return 1
        fi

        sleep 2
    done

    if [ "$ready" -ne 1 ]; then
        log "ERROR: Splunk did not return the staged SECX15 web event after indexing."
        log "Last Splunk search output:"
        printf '%s\n' "$search_output" | tail -n 25 | tee -a "$STATUS_FILE"
        return 1
    fi

    log "Verified Splunk index $SPLUNK_INDEX contains the staged suspicious web event."
}

seed_splunk() {
    ensure_splunk_ready
    ensure_index
    seed_splunk_event_rest
    wait_for_secx15_event
}

main() {
    require_root
    prepare_dirs
    log "Starting SECX15 SecVM LCA baseline."
    reset_secvm_gap
    add_routes
    write_brief
    write_web_log
    write_pcap_file
    rm -f "$OPS_DIR/SECX15-suspicious-http.pcap" "$OPS_DIR/SECX15-suspicious-http.pcapng" "$OPS_DIR/SECX15-saved-hunt-validation.txt"
    seed_splunk
    chown -R "${LAB_USER}:${LAB_USER}" "$OPS_DIR"
    chmod -R u+rwX,go+rX "$OPS_DIR"
    log "SECX15 SecVM LCA baseline complete."
}

main "$@"
