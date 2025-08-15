#!/bin/bash
set -euo pipefail

VALHEIM_DIR="${VALHEIM_DIR:-/home/steam/valheim}"
DATA_DIR="/data"
LOG_DIR="${DATA_DIR}/logs"

mkdir -p "${DATA_DIR}/worlds" "${DATA_DIR}/BepInEx/plugins" "${DATA_DIR}/BepInEx/config" "${DATA_DIR}/backups" "${LOG_DIR}"

[ -f "${VALHEIM_DIR}/libdoorstop.so" ] || { echo "Missing libdoorstop.so"; exit 10; }
[ -f "${VALHEIM_DIR}/BepInEx/core/BepInEx.Preloader.dll" ] || { echo "Missing Preloader"; exit 11; }

export LD_PRELOAD="${VALHEIM_DIR}/libdoorstop.so"
export DOORSTOP_INVOKE_DLL_PATH="${VALHEIM_DIR}/BepInEx/core/BepInEx.Preloader.dll"

link_dir () { 
  local src="$1" dest="$2"
  if [ -d "$src" ] && [ ! -L "$src" ]; then 
    [ -e "$dest" ] || mv "$src" "$dest"
    ln -sf "$dest" "$src"
  fi
}

link_dir "${VALHEIM_DIR}/BepInEx/config" "${DATA_DIR}/BepInEx/config"
link_dir "${VALHEIM_DIR}/BepInEx/plugins" "${DATA_DIR}/BepInEx/plugins"

if [ "${PRESTART_BACKUP:-1}" = "1" ]; then 
  tar czf "${DATA_DIR}/backups/prestart-$(date +%Y%m%d-%H%M%S).tgz" -C "${DATA_DIR}" worlds BepInEx/config >/dev/null 2>&1 || true
fi

cd "${VALHEIM_DIR}"
LOG_FILE="${LOG_DIR}/valheim.log"
touch "$LOG_FILE"

echo "[Valheim Entry] Starting Valheim server..."
./valheim_server.x86_64 \
  -name "${SERVER_NAME:-ValheimServer}" \
  -port "${SERVER_PORT:-2456}" \
  -world "${WORLD_NAME:-DedicatedWorld}" \
  -public "${PUBLIC:-0}" \
  -savedir "${DATA_DIR}/worlds" \
  -logFile "$LOG_FILE"
