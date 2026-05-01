#!/bin/bash
set -euo pipefail

TARGET_USER="labuser"
TARGET_HOME="/home/${TARGET_USER}"
DOWNLOADS_DIR="${TARGET_HOME}/Downloads"
OUTDIR="${TARGET_HOME}/Documents/ThreatIntel"

BRIEF_FILE="${OUTDIR}/SECX12-Intel-Brief.txt"
WEB_LOG_FILE="${OUTDIR}/SECX12-web-access.log"
STATUS_FILE="${OUTDIR}/SECX12-capture-status.log"
FINAL_PCAPNG="${OUTDIR}/SECX12-DVWA-Traffic.pcapng"

TMP_DUMPCAP="/tmp/SECX12-DVWA-Traffic.pcapng"
TMP_TCPDUMP="/tmp/SECX12-DVWA-Traffic.pcap"

TARGET_IP="192.168.20.10"
TARGET_GW="192.168.30.2"

SPLUNK_HOME="/opt/splunk"
SPLUNK_BIN="${SPLUNK_HOME}/bin/splunk"
SPLUNK_WEB_URL="http://127.0.0.1:8000"
ADMIN_USER="admin"
ADMIN_PASS="Passw0rd!"
INDEX_NAME="secx12_web"

if [ "$(id -un)" != "${TARGET_USER}" ]; then
  echo "Run this script as ${TARGET_USER}, not from sudo su."
  exit 1
fi

sudo -v || {
  echo "ERROR: sudo authentication failed."
  exit 1
}

mkdir -p "${OUTDIR}"
rm -f "${STATUS_FILE}"
touch "${STATUS_FILE}"

log() {
  echo "$*" | tee -a "${STATUS_FILE}"
}

log "Preparing ThreatIntel staging files..."

sudo mkdir -p "${OUTDIR}"
sudo chown -R "${TARGET_USER}:${TARGET_USER}" "${OUTDIR}"

sudo rm -f "${FINAL_PCAPNG}" "${TMP_DUMPCAP}" "${TMP_TCPDUMP}"
rm -f "${BRIEF_FILE}" "${WEB_LOG_FILE}" "${OUTDIR}/SECX12-suspicious-http.pcapng"

cat > "${BRIEF_FILE}" <<'EOINTEL'
SECX12 Threat Intel Brief

Observed indicators:
- User-Agent: sqlmap/1.7
- Targeted path: /dvwa/vulnerabilities/exec/
- Suspicious source: 192.168.30.10
- Target web host: 192.168.20.10

Analyst task:
1. Review the packet capture for matching HTTP indicators.
2. Use Splunk to hunt for the suspicious User-Agent and targeted DVWA path.
3. Build a tuned search that narrows the hunt to suspicious DVWA execution activity.
EOINTEL

ts1="$(date '+%d/%b/%Y:%H:%M:%S %z')"
ts2="$(date '+%d/%b/%Y:%H:%M:%S %z')"
ts3="$(date '+%d/%b/%Y:%H:%M:%S %z')"
ts4="$(date '+%d/%b/%Y:%H:%M:%S %z')"

cat > "${WEB_LOG_FILE}" <<EOLOG
192.168.30.10 - - [${ts1}] "GET / HTTP/1.1" 200 1179 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64)"
192.168.30.10 - - [${ts2}] "GET /dvwa/login.php HTTP/1.1" 200 2066 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64)"
192.168.30.10 - - [${ts3}] "GET /dvwa/vulnerabilities/exec/ HTTP/1.1" 200 2145 "-" "sqlmap/1.7"
192.168.30.10 - - [${ts4}] "GET /dvwa/vulnerabilities/exec/?ip=127.0.0.1 HTTP/1.1" 200 2411 "-" "sqlmap/1.7"
EOLOG

sudo chown "${TARGET_USER}:${TARGET_USER}" "${BRIEF_FILE}" "${WEB_LOG_FILE}"

log "Preparing Splunk configuration..."

SPLUNK_DEB="$(find "${DOWNLOADS_DIR}" -maxdepth 1 -type f -name 'splunk-*.deb' | sort | tail -n 1)"
if [ -z "${SPLUNK_DEB}" ]; then
  log "ERROR: Could not find a Splunk .deb package in ${DOWNLOADS_DIR}"
  exit 1
fi

if [ -x "${SPLUNK_BIN}" ]; then
  log "Stopping existing Splunk instance..."
  sudo "${SPLUNK_BIN}" stop --accept-license --answer-yes --no-prompt >/dev/null 2>&1 || true
fi

log "Removing old Splunk package and state..."
sudo dpkg --purge splunk >/dev/null 2>&1 || true
sudo rm -rf "${SPLUNK_HOME}"

log "Installing Splunk from ${SPLUNK_DEB}..."
sudo dpkg -i "${SPLUNK_DEB}" >/dev/null 2>&1 || {
  log "ERROR: Failed to install Splunk from ${SPLUNK_DEB}"
  exit 1
}

sudo mkdir -p "${SPLUNK_HOME}/etc/system/local"
sudo mkdir -p "${SPLUNK_HOME}/etc/users/${ADMIN_USER}/search/local"

sudo tee "${SPLUNK_HOME}/etc/system/local/user-seed.conf" >/dev/null <<EOF
[user_info]
USERNAME = ${ADMIN_USER}
PASSWORD = ${ADMIN_PASS}
EOF

sudo tee "${SPLUNK_HOME}/etc/system/local/indexes.conf" >/dev/null <<EOF
[${INDEX_NAME}]
homePath   = \$SPLUNK_DB/${INDEX_NAME}/db
coldPath   = \$SPLUNK_DB/${INDEX_NAME}/colddb
thawedPath = \$SPLUNK_DB/${INDEX_NAME}/thaweddb
EOF

sudo rm -f "${SPLUNK_HOME}/etc/users/${ADMIN_USER}/search/local/savedsearches.conf"
sudo rm -rf "${SPLUNK_HOME}/var/lib/splunk/${INDEX_NAME}"

log "Starting Splunk..."
sudo "${SPLUNK_BIN}" start --run-as-root --accept-license --answer-yes --no-prompt >/dev/null 2>&1 || {
  log "ERROR: Failed to start Splunk."
  exit 1
}

ready=0
for i in $(seq 1 30); do
  if curl -s --connect-timeout 2 "${SPLUNK_WEB_URL}" >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 2
done

if [ "${ready}" -ne 1 ]; then
  log "ERROR: Splunk did not become ready on ${SPLUNK_WEB_URL}"
  exit 1
fi

log "Loading staged web log into Splunk..."
sudo "${SPLUNK_BIN}" add oneshot "${WEB_LOG_FILE}" -index "${INDEX_NAME}" -sourcetype access_combined -auth "${ADMIN_USER}:${ADMIN_PASS}" >/dev/null 2>&1 || {
  log "ERROR: Failed to ingest ${WEB_LOG_FILE} into ${INDEX_NAME}"
  exit 1
}

log "Updating route to ${TARGET_IP} via ${TARGET_GW}..."
sudo ip route replace "${TARGET_IP}" via "${TARGET_GW}" >> "${STATUS_FILE}" 2>&1 || {
  log "ERROR: Could not update the route to ${TARGET_IP}"
  exit 1
}

IFACE="$(ip route get "${TARGET_IP}" 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')"
if [ -z "${IFACE}" ]; then
  log "ERROR: Could not determine the interface for ${TARGET_IP}"
  exit 1
fi

log "Using interface: ${IFACE}"

request_url() {
  local url="$1"
  local ua="$2"
  log "Requesting: ${url}"
  local code
  if code="$(curl -A "${ua}" -sS -o /dev/null -w '%{http_code}' --connect-timeout 5 --max-time 10 "${url}" 2>> "${STATUS_FILE}")"; then
    log "Result: ${code}"
  else
    log "Result: curl_failed"
  fi
}

if command -v dumpcap >/dev/null 2>&1; then
  log "Starting capture with dumpcap..."
  sudo dumpcap -i "${IFACE}" -a duration:15 -f "host ${TARGET_IP} and tcp port 80" -w "${TMP_DUMPCAP}" >/dev/null 2>&1 &
  CAP_PID=$!
  sleep 2

  request_url "http://${TARGET_IP}/dvwa/login.php" "Mozilla/5.0"
  request_url "http://${TARGET_IP}/dvwa/vulnerabilities/exec/" "sqlmap/1.7"
  request_url "http://${TARGET_IP}/dvwa/vulnerabilities/exec/?ip=127.0.0.1" "sqlmap/1.7"

  wait "${CAP_PID}" 2>/dev/null || true

  if [ ! -s "${TMP_DUMPCAP}" ]; then
    log "ERROR: The capture file was not created at ${TMP_DUMPCAP}"
    exit 1
  fi

  sudo mv "${TMP_DUMPCAP}" "${FINAL_PCAPNG}"
  sudo chown "${TARGET_USER}:${TARGET_USER}" "${FINAL_PCAPNG}"
else
  if ! command -v tcpdump >/dev/null 2>&1; then
    log "ERROR: Neither dumpcap nor tcpdump is installed."
    exit 1
  fi

  log "Starting capture with tcpdump..."
  sudo tcpdump -i "${IFACE}" -s 0 -U -w "${TMP_TCPDUMP}" "host ${TARGET_IP} and tcp port 80" >/dev/null 2>&1 &
  CAP_PID=$!
  sleep 2

  request_url "http://${TARGET_IP}/dvwa/login.php" "Mozilla/5.0"
  request_url "http://${TARGET_IP}/dvwa/vulnerabilities/exec/" "sqlmap/1.7"
  request_url "http://${TARGET_IP}/dvwa/vulnerabilities/exec/?ip=127.0.0.1" "sqlmap/1.7"

  sleep 2
  sudo kill -INT "${CAP_PID}" >/dev/null 2>&1 || true
  wait "${CAP_PID}" 2>/dev/null || true

  if [ ! -s "${TMP_TCPDUMP}" ]; then
    log "ERROR: The capture file was not created at ${TMP_TCPDUMP}"
    exit 1
  fi

  if command -v editcap >/dev/null 2>&1; then
    sudo editcap -F pcapng "${TMP_TCPDUMP}" "${FINAL_PCAPNG}" >/dev/null 2>&1 || {
      log "ERROR: editcap could not convert the capture to pcapng."
      exit 1
    }
    sudo rm -f "${TMP_TCPDUMP}"
  else
    sudo mv "${TMP_TCPDUMP}" "${FINAL_PCAPNG}"
  fi

  sudo chown "${TARGET_USER}:${TARGET_USER}" "${FINAL_PCAPNG}"
fi

if [ ! -s "${FINAL_PCAPNG}" ]; then
  log "ERROR: The final capture file was not created at ${FINAL_PCAPNG}"
  exit 1
fi

log "Capture complete: ${FINAL_PCAPNG}"
ls -lh "${FINAL_PCAPNG}" | tee -a "${STATUS_FILE}"