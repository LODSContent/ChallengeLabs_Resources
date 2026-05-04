#!/bin/bash
# Title: Lab13 Part0 helper - Stage incident artifacts on SecVM
# Description: Creates the incident brief, packet capture, Apache log snapshot, and tool-usage wrappers used by Lab 13.
# Target: SecVM
# Version: 2026.04.30

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this script with sudo." >&2
  exit 1
fi

USER_HOME="/home/labuser"
DOCS="$USER_HOME/Documents"
INC_DIR="$DOCS/Incident"
LOGFILE="$DOCS/.secx13-tool-usage.log"

TARGET_IP="192.168.20.10"
TARGET_GW="192.168.30.2"

TMP_PCAPNG="/tmp/SECX13-Incident-Traffic.pcapng"
TMP_PCAP="/tmp/SECX13-Incident-Traffic.pcap"
FINAL_PCAPNG="$INC_DIR/SECX13-Incident-Traffic.pcapng"

mkdir -p "$INC_DIR"

cat > "$INC_DIR/SECX13-Incident-Brief.txt" <<'EOT'
SECX13 Incident Brief
Summary:
Multiple suspicious HTTP requests were observed against DVWA. The requests targeted the DVWA file inclusion module and used an automated HTTP client.
Indicators:
- Source IP: 192.168.30.10
- User-Agent: python-requests/2.31
- Target Path: /dvwa/vulnerabilities/fi/
- Suspicious Parameter: page=../../../../etc/passwd
Likely Cause:
An automated local file inclusion style probe was performed against a public-facing application path.
Initial Containment Goal:
Prevent remote access to the targeted file inclusion module while preserving normal access to the rest of DVWA.
Automation Goal:
Create a repeatable containment script that can re-apply the path restriction and reload Apache safely.
EOT

cat > "$INC_DIR/SECX13-dvwa-access.log" <<'EOT'
192.168.30.10 - - [21/Apr/2026:10:03:12 +0000] "GET /dvwa/vulnerabilities/fi/?page=../../../../etc/passwd HTTP/1.1" 200 612 "-" "python-requests/2.31"
192.168.30.10 - - [21/Apr/2026:10:03:13 +0000] "GET /dvwa/vulnerabilities/fi/?page=../../../../etc/hosts HTTP/1.1" 200 612 "-" "python-requests/2.31"
192.168.30.10 - - [21/Apr/2026:10:03:17 +0000] "GET /dvwa/login.php HTTP/1.1" 200 1432 "-" "Mozilla/5.0"
EOT

rm -f "$FINAL_PCAPNG" "$TMP_PCAPNG" "$TMP_PCAP" "$INC_DIR/SECX13-suspicious-http.pcapng"

ip route replace "$TARGET_IP" via "$TARGET_GW" >/dev/null 2>&1 || true

iface="$(ip route get "$TARGET_IP" 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
if [ -z "$iface" ]; then
  echo "ERROR: could not determine the active interface for DVWA traffic." >&2
  exit 1
fi

generate_requests() {
  /usr/bin/curl -A "Mozilla/5.0" -s "http://${TARGET_IP}/dvwa/login.php" >/dev/null 2>&1 || true
  /usr/bin/curl -A "python-requests/2.31" -s "http://${TARGET_IP}/dvwa/vulnerabilities/fi/?page=../../../../etc/passwd" >/dev/null 2>&1 || true
  /usr/bin/curl -A "python-requests/2.31" -s "http://${TARGET_IP}/dvwa/vulnerabilities/fi/?page=../../../../etc/hosts" >/dev/null 2>&1 || true
}

if command -v dumpcap >/dev/null 2>&1; then
  dumpcap -i "$iface" -a duration:6 -f "host ${TARGET_IP} and tcp port 80" -w "$TMP_PCAPNG" >/dev/null 2>&1 &
  cap_pid=$!
  sleep 1
  generate_requests
  wait "$cap_pid" || true

  if [ ! -s "$TMP_PCAPNG" ]; then
    echo "ERROR: dumpcap did not create the incident capture." >&2
    exit 1
  fi

  mv "$TMP_PCAPNG" "$FINAL_PCAPNG"

elif command -v tcpdump >/dev/null 2>&1; then
  tcpdump -i "$iface" -s 0 -U -w "$TMP_PCAP" "host ${TARGET_IP} and tcp port 80" >/dev/null 2>&1 &
  cap_pid=$!
  sleep 1
  generate_requests
  sleep 1
  kill -INT "$cap_pid" >/dev/null 2>&1 || true
  wait "$cap_pid" || true

  if [ ! -s "$TMP_PCAP" ]; then
    echo "ERROR: tcpdump did not create the incident capture." >&2
    exit 1
  fi

  if command -v editcap >/dev/null 2>&1; then
    editcap -F pcapng "$TMP_PCAP" "$FINAL_PCAPNG" >/dev/null 2>&1 || {
      echo "ERROR: editcap could not convert the incident capture to pcapng." >&2
      exit 1
    }
    rm -f "$TMP_PCAP"
  else
    mv "$TMP_PCAP" "$FINAL_PCAPNG"
  fi

else
  echo "ERROR: Neither dumpcap nor tcpdump was found on SecVM." >&2
  exit 1
fi

: > "$LOGFILE"

cat > /usr/local/bin/grep <<EOF2
#!/bin/bash
echo "\$(date -u +%FT%TZ)|GREP|\$*" >> "$LOGFILE"
exec /usr/bin/grep "\$@"
EOF2
chmod +x /usr/local/bin/grep

cat > /usr/local/bin/curl <<EOF3
#!/bin/bash
echo "\$(date -u +%FT%TZ)|CURL|\$*" >> "$LOGFILE"
exec /usr/bin/curl "\$@"
EOF3
chmod +x /usr/local/bin/curl

chown -R labuser:labuser "$DOCS"

echo "Lab13 incident artifacts created in $INC_DIR"