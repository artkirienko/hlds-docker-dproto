FROM debian:buster-slim

ARG hlds_build=7882
ARG metamod_version=1.21p38
ARG amxmod_version=1.8.2
ARG jk_botti_version=1.43
ARG steamcmd_url=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
ARG hlds_url="https://github.com/DevilBoy-eXe/hlds/releases/download/$hlds_build/hlds_build_$hlds_build.zip"
ARG metamod_url="https://github.com/Bots-United/metamod-p/releases/download/v$metamod_version/metamod_i686_linux_win32-$metamod_version.tar.xz"
ARG amxmod_url="http://www.amxmodx.org/release/amxmodx-$amxmod_version-base-linux.tar.gz"
ARG jk_botti_url="http://koti.kapsi.fi/jukivili/web/jk_botti/jk_botti-$jk_botti_version-release.tar.xz"

# Fix warning:
# WARNING: setlocale('en_US.UTF-8') failed, using locale: 'C'.
# International characters may not work.
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales=2.28-10 \
 && rm -rf /var/lib/apt/lists/* \
 && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8
ENV LC_ALL en_US.UTF-8

# Fix error:
# Unable to determine CPU Frequency. Try defining CPU_MHZ.
# Exiting on SPEW_ABORT
ENV CPU_MHZ=2300

RUN groupadd -r steam && useradd -r -g steam -m -d /opt/steam steam

RUN apt-get -y update && apt-get install -y --no-install-recommends \
    ca-certificates=20190110 \
    curl=7.64.0-4+deb10u1 \
    lib32gcc1=1:8.3.0-6 \
    unzip=6.0-23+deb10u1 \
    xz-utils=5.2.4-1 \
    zip=3.0-11+b1 \
 && apt-get -y autoremove \
 && rm -rf /var/lib/apt/lists/*

USER steam
WORKDIR /opt/steam
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
COPY ./lib/hlds.install /opt/steam

RUN curl -sL "$steamcmd_url" | tar xzvf - \
    && ./steamcmd.sh +runscript hlds.install

RUN curl -sLJO "$hlds_url" \
    && unzip "hlds_build_$hlds_build.zip" -d "/opt/steam" \
    && cp -R "hlds_build_$hlds_build"/* hlds/ \
    && rm -rf "hlds_build_$hlds_build" "hlds_build_$hlds_build.zip"

# Fix error that steamclient.so is missing
RUN mkdir -p "$HOME/.steam" \
    && ln -s /opt/steam/linux32 "$HOME/.steam/sdk32"

# Fix warnings:
# couldn't exec listip.cfg
# couldn't exec banned.cfg
RUN touch /opt/steam/hlds/valve/listip.cfg
RUN touch /opt/steam/hlds/valve/banned.cfg

# Install Metamod-P
RUN mkdir -p /opt/steam/hlds/valve/addons/metamod/dlls \
    && touch /opt/steam/hlds/valve/addons/metamod/plugins.ini
RUN curl -sqL "$metamod_url" | tar -C /opt/steam/hlds/valve/addons/metamod/dlls -xJ
RUN sed -i 's/dlls\/hl\.so/addons\/metamod\/dlls\/metamod.so/g' /opt/steam/hlds/valve/liblist.gam

# Install AMX mod X
RUN curl -sqL "$amxmod_url" | tar -C /opt/steam/hlds/valve/ -zxvf - \
    && echo 'linux addons/amxmodx/dlls/amxmodx_mm_i386.so' >> /opt/steam/hlds/valve/addons/metamod/plugins.ini
RUN cat /opt/steam/hlds/valve/mapcycle.txt >> /opt/steam/hlds/valve/addons/amxmodx/configs/maps.ini

# Install dproto
RUN mkdir -p /opt/steam/hlds/valve/addons/dproto
COPY lib/dproto/bin/Linux/dproto_i386.so /opt/steam/hlds/valve/addons/dproto/dproto_i386.so
COPY lib/dproto/dproto.cfg /opt/steam/hlds/valve/dproto.cfg
RUN echo 'linux addons/dproto/dproto_i386.so' >> /opt/steam/hlds/valve/addons/metamod/plugins.ini
COPY lib/dproto/amxx/* /opt/steam/hlds/valve/addons/amxmodx/scripting/

# Install jk_botti
RUN curl -sqL "$jk_botti_url" | tar -C /opt/steam/hlds/valve/ -xJ \
    && echo 'linux addons/jk_botti/dlls/jk_botti_mm_i386.so' >> /opt/steam/hlds/valve/addons/metamod/plugins.ini

WORKDIR /opt/steam/hlds

# Copy default config
COPY valve valve

RUN chmod +x hlds_run hlds_linux

RUN echo 70 > steam_appid.txt

EXPOSE 27015
EXPOSE 27015/udp

# Start server
ENTRYPOINT ["./hlds_run", "-timeout 3", "-pingboost 1"]

# Default start parameters
CMD ["+map crossfire", "+rcon_password 12345678"]
