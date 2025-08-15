FROM debian:bookworm-slim
ARG BEPINEX_VERSION=5.4.23.3
ARG BEPINEX_FILENAME="BepInExPack_Valheim_${BEPINEX_VERSION}.zip"
ARG BEPINEX_BASEURL="https://github.com/BepInEx/BepInEx/releases/download/v${BEPINEX_VERSION}"
ENV STEAMCMDDIR=/opt/steamcmd VALHEIM_DIR=/home/steam/valheim DATA_DIR=/data DOORSTOP_ENABLE=TRUE
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates lib32gcc-s1 curl tar jq unzip rsync procps tini && rm -rf /var/lib/apt/lists/*
RUN useradd -m -d /home/steam -s /bin/bash steam
RUN mkdir -p $STEAMCMDDIR && chown steam:steam $STEAMCMDDIR
USER steam
RUN curl -sSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xz -C $STEAMCMDDIR
RUN mkdir -p $VALHEIM_DIR && $STEAMCMDDIR/steamcmd.sh +login anonymous +app_update 896660 validate +quit
WORKDIR /tmp
RUN curl -fSL -o ${BEPINEX_FILENAME} ${BEPINEX_BASEURL}/${BEPINEX_FILENAME} && unzip ${BEPINEX_FILENAME} -d /tmp/bep && rsync -a /tmp/bep/ $VALHEIM_DIR/ && test -f $VALHEIM_DIR/libdoorstop.so && test -f $VALHEIM_DIR/BepInEx/core/BepInEx.Preloader.dll && rm -rf /tmp/bep ${BEPINEX_FILENAME}
COPY --chown=steam:steam entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
VOLUME ["/data"]
EXPOSE 2456/udp 2457/udp 2458/udp
ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/entrypoint.sh"]
