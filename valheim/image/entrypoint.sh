#!/bin/bash
set -euo pipefail

VALHEIM_DIR="${VALHEIM_DIR:-/home/steam/valheim}"
DATA_DIR="/data"
LOG_DIR="${DATA_DIR}/logs"

# /data はホスト側を 1000:1000 所有に統一しておく前提（コンテナ内 chown は行わない）
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
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# BepInEx ランナー必須
if [ ! -x "./run_bepinex.sh" ]; then
  echo "Error: run_bepinex.sh not found or not executable in ${VALHEIM_DIR}" 1>&2
  ls -la
  exit 12
fi

echo "[Valheim Entry] Starting via BepInEx..."
# 引数を透過し、標準出力もファイルへ tee で保存（healthcheck 用の grep も安定）
exec bash -lc "./run_bepinex.sh \
  -name '${SERVER_NAME:-ValheimServer}' \
  -port '${SERVER_PORT:-2456}' \
  -world '${WORLD_NAME:-DedicatedWorld}' \
  -public '${PUBLIC:-0}' \
  -savedir '${DATA_DIR}/worlds' \
  -logFile '${LOG_FILE}' 2>&1 | tee -a '${LOG_FILE}'"
