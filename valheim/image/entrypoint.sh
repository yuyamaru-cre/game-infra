#!/bin/bash
set -euo pipefail

VALHEIM_DIR="${VALHEIM_DIR:-/home/steam/valheim}"
DATA_DIR="/data"
LOG_DIR="${DATA_DIR}/logs"

# /dataディレクトリの権限修正
sudo chown -R steam:steam "$DATA_DIR" 2>/dev/null || true

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

echo "[Valheim Entry] Directory contents:"
ls -la .
echo "[Valheim Entry] Looking for server executable..."
if [ ! -f "./start_server_xvfb.sh" ]; then
  echo "start_server_xvfb.sh not found, checking alternatives..."
  find . -name "*server*" -o -name "*valheim*" | head -10
  if [ -f "./start_server.sh" ]; then
    echo "Using start_server.sh"
    export SERVER_NAME="${SERVER_NAME:-ValheimServer}"
    export SERVER_PORT="${SERVER_PORT:-2456}"
    export WORLD_NAME="${WORLD_NAME:-DedicatedWorld}"
    export PUBLIC="${PUBLIC:-0}"
    export SERVER_SAVEDIR="${DATA_DIR}/worlds"
    export SERVER_LOG_FILE="$LOG_FILE"
    exec ./start_server.sh
  elif [ -f "./valheim_server.x86_64" ]; then
    echo "Using valheim_server.x86_64 with batchmode"
    exec ./valheim_server.x86_64 -batchmode -nographics -name "${SERVER_NAME:-ValheimServer}" -port "${SERVER_PORT:-2456}" -world "${WORLD_NAME:-DedicatedWorld}" -public "${PUBLIC:-0}" -savedir "${DATA_DIR}/worlds" -logFile "$LOG_FILE"
  fi
  exit 12
fi
echo "[Valheim Entry] Starting Valheim server..."
./start_server_xvfb.sh \
  -name "${SERVER_NAME:-ValheimServer}" \
  -port "${SERVER_PORT:-2456}" \
  -world "${WORLD_NAME:-DedicatedWorld}" \
  -public "${PUBLIC:-0}" \
  -savedir "${DATA_DIR}/worlds" \
  -logFile "$LOG_FILE"
