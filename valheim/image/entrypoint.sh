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
  tar czf "${DATA_DIR}/backups/prestart-$(date +%Y%m%d-%H%M%S).tgz" -C "${DATA_DIR}" worlds BepInEx/config > /dev/null 2>&1 || true
fi

cd "${VALHEIM_DIR}"
# Ensure Steam SDK64 client is discoverable
mkdir -p "/home/steam/.steam/sdk64" || true
if [ -f "${VALHEIM_DIR}/linux64/steamclient.so" ]; then
  ln -sf "${VALHEIM_DIR}/linux64/steamclient.so" "/home/steam/.steam/sdk64/steamclient.so"
fi
# Library path for steamclient and natives
export LD_LIBRARY_PATH="${VALHEIM_DIR}/linux64:${VALHEIM_DIR}:${LD_LIBRARY_PATH:-}"

# 日付付きログと latest リンクを準備
TODAY="$(date +%Y%m%d)"
LOG_DATED="${LOG_DIR}/valheim_${TODAY}.log"
LOG_LATEST="${LOG_DIR}/valheim_latest.log"
mkdir -p "${LOG_DIR}"
# latest を当日ファイルへ向ける（当日初回起動時に新規作成）
ln -sfn "$(basename "${LOG_DATED}")" "${LOG_LATEST}"
# 7世代保持（valheim_*.log を新しい順に並べ、8本目以降削除）
ls -1t ${LOG_DIR}/valheim_*.log 2>/dev/null | tail -n +8 | xargs -r rm -f || true

LOG_FILE="${LOG_DATED}"
: > "${LOG_FILE}"  # 明示的にファイルを作成（追記はValheim/tee側が行う)

# PASSWORD があれば起動引数へ反映
PASSWORD_ARG=""
if [ -n "${PASSWORD:-}" ]; then
  PASSWORD_ARG="-password '${PASSWORD}'"
fi

# 実行権限の保険
if [ -f "${VALHEIM_DIR}/run_bepinex.sh" ] && [ ! -x "${VALHEIM_DIR}/run_bepinex.sh" ]; then
  chmod +x "${VALHEIM_DIR}/run_bepinex.sh" || true
fi
if [ -f "${VALHEIM_DIR}/valheim_server.x86_64" ] && [ ! -x "${VALHEIM_DIR}/valheim_server.x86_64" ]; then
  chmod +x "${VALHEIM_DIR}/valheim_server.x86_64" || true
fi

# 必須ファイル確認
if [ ! -x "./run_bepinex.sh" ]; then
  echo "Error: run_bepinex.sh not found or not executable in ${VALHEIM_DIR}" 1>&2
  ls -la
  exit 12
fi
if [ ! -x "./valheim_server.x86_64" ]; then
  echo "Error: valheim_server.x86_64 not found or not executable in ${VALHEIM_DIR}" 1>&2
  ls -la
  exit 13
fi

# 起動（1行実行・BepInEx 経由・ヘッドレス）＋ tee でファイルにも出力
echo "[Valheim Entry] Starting via BepInEx..."
exec bash -lc "/home/steam/valheim/run_bepinex.sh /home/steam/valheim/valheim_server.x86_64 -batchmode -nographics -name '${SERVER_NAME:-ValheimServer}' -port '${SERVER_PORT:-2456}' -world '${WORLD_NAME:-DedicatedWorld}' -public '${PUBLIC:-0}' ${PASSWORD_ARG} -savedir '${DATA_DIR}/worlds' -logFile '${LOG_FILE}' 2>&1 | tee -a '${LOG_FILE}'"
