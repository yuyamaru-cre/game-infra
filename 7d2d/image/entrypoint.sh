#!/bin/bash
set -euo pipefail

SDTD_DIR="${SDTD_DIR:-/home/steam/7d2d}"
DATA_DIR="/data"
CONFIG_TMPL="${SDTD_DIR}/serverconfig.xml.template"
GENERATED_DIR="${DATA_DIR}/generated"
CONFIG_OUT="${GENERATED_DIR}/serverconfig.xml"
LOG_DIR="${DATA_DIR}/logs"
SAVE_DIR="${DATA_DIR}/saves"
BACKUP_DIR="${DATA_DIR}/backups"

mkdir -p "$LOG_DIR" "$SAVE_DIR" "$BACKUP_DIR" "$GENERATED_DIR"

if [ "${AUTO_UPDATE:-1}" = "1" ]; then
  echo "[7d2d Entry] Updating..."
  "${STEAMCMDDIR}/steamcmd.sh" +login anonymous +app_update 294420 validate +quit || echo "[Warn] update failed"
fi

cp "$CONFIG_TMPL" "$CONFIG_OUT"

LOG_FILE="${LOG_DIR}/output-$(date +%Y%m%d-%H%M%S).log"
ln -sf "$(basename "$LOG_FILE")" "${LOG_DIR}/latest.log"

cd "$SDTD_DIR"
echo "[7d2d Entry] Start..."
./startserver.sh -configfile="$CONFIG_OUT" -logfile "$LOG_FILE"
