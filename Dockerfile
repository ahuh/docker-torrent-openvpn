# Transmission and OpenVPN
#
# Version 1.0

FROM resin/rpi-raspbian:jessie
MAINTAINER maintainer "ahuh"

# Volume watchdir: use it in transmission configuration for torrents to scan
# WARNING: must have read/write accept for execution user (PUID/PGID)
VOLUME /watchdir
# Volume downloaddir: use it in transmission configuration for completed dir
# WARNING: must have read/write accept for execution user (PUID/PGID)
VOLUME /downloaddir
# Volume incompletedir: use it in transmission configuration for incomplete dir
# WARNING: must have read/write accept for execution user (PUID/PGID)
VOLUME /incompletedir
# Volume transmissionhome: transmission home directory (generated at first start if needed)
# WARNING: must have read/write accept for execution user (PUID/PGID)
VOLUME /transmissionhome
# Volume squidconfig: squid3 config directory (generated at first start if needed)
# WARNING: must have read/write accept for execution user (PUID/PGID)
VOLUME /squidconfig
# Volume squidlogs: squid3 log directory (generated at first start)
VOLUME /var/log/squid3
# Volume userhome: home directory for execution user
VOLUME /config

# Set environment variables
# - Set OpenVPN IDs (must be overloaded), all Transmission parameters, and execution user (PUID/PGID)
ENV ENABLE_TRANSMISSION_WEB_CONTROL=\
	OPENVPN_USERNAME=**None** \
    OPENVPN_PASSWORD=**None** \
    OPENVPN_PROVIDER=**None** \
    "SICKRAGE_LABEL=medusa" \
    "TRANSMISSION_ALT_SPEED_DOWN=50" \
    "TRANSMISSION_ALT_SPEED_ENABLED=false" \
    "TRANSMISSION_ALT_SPEED_TIME_BEGIN=540" \
    "TRANSMISSION_ALT_SPEED_TIME_DAY=127" \
    "TRANSMISSION_ALT_SPEED_TIME_ENABLED=false" \
    "TRANSMISSION_ALT_SPEED_TIME_END=1020" \
    "TRANSMISSION_ALT_SPEED_UP=50" \
    "TRANSMISSION_BIND_ADDRESS_IPV4=0.0.0.0" \
    "TRANSMISSION_BIND_ADDRESS_IPV6=::" \
    "TRANSMISSION_BLOCKLIST_ENABLED=false" \
    "TRANSMISSION_BLOCKLIST_URL=http://www.example.com/blocklist" \
    "TRANSMISSION_CACHE_SIZE_MB=4" \
    "TRANSMISSION_DHT_ENABLED=true" \
    "TRANSMISSION_DOWNLOAD_DIR=/downloaddir" \
    "TRANSMISSION_DOWNLOAD_QUEUE_ENABLED=true" \
    "TRANSMISSION_DOWNLOAD_QUEUE_SIZE=50" \
    "TRANSMISSION_ENCRYPTION=1" \
    "TRANSMISSION_IDLE_SEEDING_LIMIT=30" \
    "TRANSMISSION_IDLE_SEEDING_LIMIT_ENABLED=false" \
    "TRANSMISSION_INCOMPLETE_DIR=/incompletedir" \
    "TRANSMISSION_INCOMPLETE_DIR_ENABLED=true" \
    "TRANSMISSION_LPD_ENABLED=true" \
    "TRANSMISSION_MESSAGE_LEVEL=2" \
    "TRANSMISSION_PEER_CONGESTION_ALGORITHM=" \
    "TRANSMISSION_PEER_ID_TTL_HOURS=6" \
    "TRANSMISSION_PEER_LIMIT_GLOBAL=500" \
    "TRANSMISSION_PEER_LIMIT_PER_TORRENT=70" \
    "TRANSMISSION_PEER_PORT=51413" \
    "TRANSMISSION_PEER_PORT_RANDOM_HIGH=65535" \
    "TRANSMISSION_PEER_PORT_RANDOM_LOW=49152" \
    "TRANSMISSION_PEER_PORT_RANDOM_ON_START=false" \
    "TRANSMISSION_PEER_SOCKET_TOS=default" \
    "TRANSMISSION_PEX_ENABLED=true" \
    "TRANSMISSION_PORT_FORWARDING_ENABLED=false" \
    "TRANSMISSION_PREALLOCATION=1" \
    "TRANSMISSION_PREFETCH_ENABLED=1" \
    "TRANSMISSION_QUEUE_STALLED_ENABLED=false" \
    "TRANSMISSION_QUEUE_STALLED_MINUTES=30" \
    "TRANSMISSION_RATIO_LIMIT=2" \
    "TRANSMISSION_RATIO_LIMIT_ENABLED=false" \
    "TRANSMISSION_RENAME_PARTIAL_FILES=true" \
    "TRANSMISSION_RPC_AUTHENTICATION_REQUIRED=false" \
    "TRANSMISSION_RPC_BIND_ADDRESS=0.0.0.0" \
    "TRANSMISSION_RPC_ENABLED=true" \
    "TRANSMISSION_RPC_HOST_WHITELIST=" \
    "TRANSMISSION_RPC_HOST_WHITELIST_ENABLED=false" \
    "TRANSMISSION_RPC_PASSWORD=password" \
    "TRANSMISSION_RPC_PORT=9091" \
    "TRANSMISSION_RPC_URL=/transmission/" \
    "TRANSMISSION_RPC_USERNAME=username" \
    "TRANSMISSION_RPC_WHITELIST=127.0.0.1" \
    "TRANSMISSION_RPC_WHITELIST_ENABLED=false" \
    "TRANSMISSION_SCRAPE_PAUSED_TORRENTS_ENABLED=true" \
    "TRANSMISSION_SCRIPT_TORRENT_DONE_ENABLED=false" \
    "TRANSMISSION_SCRIPT_TORRENT_DONE_FILENAME=" \
    "TRANSMISSION_SEED_QUEUE_ENABLED=false" \
    "TRANSMISSION_SEED_QUEUE_SIZE=10" \
    "TRANSMISSION_SPEED_LIMIT_DOWN=100" \
    "TRANSMISSION_SPEED_LIMIT_DOWN_ENABLED=false" \
    "TRANSMISSION_SPEED_LIMIT_UP=50" \
    "TRANSMISSION_SPEED_LIMIT_UP_ENABLED=true" \
    "TRANSMISSION_START_ADDED_TORRENTS=true" \
    "TRANSMISSION_TRASH_ORIGINAL_TORRENT_FILES=false" \
    "TRANSMISSION_UMASK=2" \
    "TRANSMISSION_UPLOAD_SLOTS_PER_TORRENT=14" \
    "TRANSMISSION_UTP_ENABLED=true" \
    "TRANSMISSION_WATCH_DIR=/watchdir" \
    "TRANSMISSION_WATCH_DIR_ENABLED=true" \
    "TRANSMISSION_HOME=/transmissionhome" \
    PUID=\
    PGID=
# - Set xterm for nano and iftop
ENV TERM xterm

# Remove previous apt repos
RUN rm -rf /etc/apt/preferences.d* \
	&& mkdir /etc/apt/preferences.d \
	&& rm -rf /etc/apt/sources.list* \
	&& mkdir /etc/apt/sources.list.d
	
# Copy custom bashrc to root (ll aliases)
COPY root/ /root/
# Copy apt config for jessie (stable) and stretch (testing) repos
COPY preferences.d/ /etc/apt/preferences.d/
COPY sources.list.d/ /etc/apt/sources.list.d/

# Update packages and install software
RUN apt-get update \
    && apt-get install -y transmission-cli transmission-common transmission-daemon \
    && apt-get install -y squid3 \
    && apt-get install -y openvpn curl wget nano iftop \
    && apt-get install -y dumb-init -t stretch \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
    
# Create and set user & group for impersonation
RUN groupmod -g 1000 users \
    && useradd -u 911 -U -d /config -s /bin/false abc \
    && usermod -G users abc

# Copy configuration and scripts
COPY common/ /etc/common/
COPY openvpn/ /etc/openvpn/
COPY transmission/ /etc/transmission/
COPY squid3/ /etc/squid3/

# Fix execution permissions after copy 
RUN chmod +x /etc/common/*.sh \
	&& chmod +x /etc/openvpn/*.sh \
    && chmod +x /etc/transmission/*.sh \
    && chmod +x /etc/squid3/*.sh

# Expose port
EXPOSE 9091 3128

# Launch OpenVPN with transmission at container start
CMD ["dumb-init", "/etc/openvpn/start.sh"]
