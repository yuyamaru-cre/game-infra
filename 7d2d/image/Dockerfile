FROM debian:bookworm-slim
ARG SEVEN_DAYS_BRANCH=public
ENV STEAMCMDDIR=/opt/steamcmd SDTD_DIR=/server DATA_DIR=/data
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates lib32gcc-s1 curl tar unzip jq procps tini gosu xmlstarlet && rm -rf /var/lib/apt/lists/*
RUN useradd -m -d /home/steam -s /bin/bash steam
USER steam
RUN mkdir -p $STEAMCMDDIR && curl -sSL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar -xz -C $STEAMCMDDIR
RUN mkdir -p $SDTD_DIR && $STEAMCMDDIR/steamcmd.sh +login anonymous +app_update 294420 -beta ${SEVEN_DAYS_BRANCH} validate +quit
WORKDIR /server
COPY --chown=steam:steam entrypoint.sh /entrypoint.sh
COPY --chown=steam:steam serverconfig.xml.template /server/serverconfig.xml.template
RUN chmod +x /entrypoint.sh
VOLUME ["/data"]
EXPOSE 26900/udp 26900/tcp 26901/udp 26902/udp 26903/udp
ENTRYPOINT ["/usr/bin/tini","--"]
CMD ["/entrypoint.sh"]