#!/bin/sh

WAN_IP=${WAN_IP:-$(dig +short myip.opendns.com @resolver1.opendns.com)}
echo "WAN IP address is ${WAN_IP}"

if [ -n "${PGID}" ] && [ "${PGID}" != "$(id -g qbittorrent)" ]; then
  echo "Switching to PGID ${PGID}..."
  sed -i -e "s/^qbittorrent:\([^:]*\):[0-9]*/qbittorrent:\1:${PGID}/" /etc/group
  sed -i -e "s/^qbittorrent:\([^:]*\):\([0-9]*\):[0-9]*/qbittorrent:\1:\2:${PGID}/" /etc/passwd
fi
if [ -n "${PUID}" ] && [ "${PUID}" != "$(id -u qbittorrent)" ]; then
  echo "Switching to PUID ${PUID}..."
  sed -i -e "s/^qbittorrent:\([^:]*\):[0-9]*:\([0-9]*\)/qbittorrent:\1:${PUID}:\2/" /etc/passwd
fi

WEBUI_PORT=${WEBUI_PORT:-8080}
ALT_WEBUI=${ALT_WEBUI:-false}
if [ "${ALT_WEBUI}" != "true" ]; then
  ALT_WEBUI=false
fi

echo "Creating folders..."
mkdir -p /data/config \
  /data/data \
  /data/downloads \
  /data/temp \
  /data/torrents \
  /data/watch \
  /data/webui \
  ${QBITTORRENT_HOME}/.config \
  ${QBITTORRENT_HOME}/.local/share \
  /var/log/qbittorrent
if [ ! -e "${QBITTORRENT_HOME}/.config/qBittorrent" ]; then
  ln -s /data/config "${QBITTORRENT_HOME}/.config/qBittorrent"
fi
if [ ! -e "${QBITTORRENT_HOME}/.local/share/qBittorrent" ]; then
  ln -s /data/data "${QBITTORRENT_HOME}/.local/share/qBittorrent"
fi

# https://github.com/qbittorrent/qBittorrent/blob/master/src/base/settingsstorage.cpp
if [ ! -f /data/config/qBittorrent.conf ]; then
  echo "Initializing qBittorrent configuration..."
  cat > /data/config/qBittorrent.conf <<EOL
[General]
ported_to_new_savepath_system=true

[Application]
FileLogger\Enabled=true
FileLogger\Path=/var/log/qbittorrent

[LegalNotice]
Accepted=true

[Preferences]
Bittorrent\AddTrackers=false
Connection\InetAddress=${WAN_IP}
Connection\InterfaceListenIPv6=false
Connection\PortRangeMin=6881
Connection\UseUPnP=false
Downloads\PreAllocation=true
Downloads\SavePath=/media/downloads
Downloads\StartInPause=false
Downloads\TempPath=/media/downloads/temp
Downloads\TempPathEnabled=true
Downloads\FinishedTorrentExportDir=/media/downloads/torrents
General\Locale=en
General\UseRandomPort=false
WebUI\Enabled=true
WebUI\HTTPS\Enabled=false
WebUI\Address=0.0.0.0
WebUI\Port=${WEBUI_PORT}
WebUI\LocalHostAuth=false
WebUI\AlternativeUIEnabled=${ALT_WEBUI}
WebUI\RootFolder=/data/webui
WebUI\CSRFProtection=false
WebUI\HostHeaderValidation=false
EOL
fi

echo "Overriding required parameters..."
sed -i "s!ported_to_new_savepath_system.*!ported_to_new_savepath_system=true!g" /data/config/qBittorrent.conf
sed -i "s!FileLogger\\\Enabled=.*!FileLogger\\\Enabled=true!g" /data/config/qBittorrent.conf
sed -i "s!FileLogger\\\Path=.*!FileLogger\\\Path=/var/log/qbittorrent!g" /data/config/qBittorrent.conf
sed -i "s!Connection\\\InetAddress=.*!Connection\\\InetAddress=${WAN_IP}!g" /data/config/qBittorrent.conf
sed -i "s!Connection\\\InterfaceListenIPv6=.*!Connection\\\InterfaceListenIPv6=false!g" /data/config/qBittorrent.conf
sed -i "s!Connection\\\UseUPnP=.*!Connection\\\UseUPnP=false!g" /data/config/qBittorrent.conf
sed -i "s!Connection\\\InetAddress=.*!Connection\\\InetAddress=${WAN_IP}!g" /data/config/qBittorrent.conf
sed -i "s!Downloads\\\SavePath=.*!Downloads\\\SavePath=/media/downloads!g" /data/config/qBittorrent.conf
sed -i "s!Downloads\\\TempPath=.*!Downloads\\\TempPath=/media/downloads/temp!g" /data/config/qBittorrent.conf
sed -i "s!Downloads\\\TempPathEnabled=.*!Downloads\\\TempPathEnabled=true!g" /data/config/qBittorrent.conf
sed -i "s!Downloads\\\FinishedTorrentExportDir=.*!Downloads\\\FinishedTorrentExportDir=/media/downloads/torrents!g" /data/config/qBittorrent.conf
sed -i "s!WebUI\\\Enabled=.*!WebUI\\\Enabled=true!g" /data/config/qBittorrent.conf
sed -i "s!WebUI\\\Address=.*!WebUI\\\Address=0\.0\.0\.0!g" /data/config/qBittorrent.conf
sed -i "s!WebUI\\\Port=.*!WebUI\\\Port=${WEBUI_PORT}!g" /data/config/qBittorrent.conf
sed -i "s!WebUI\\\LocalHostAuth=.*!WebUI\\\LocalHostAuth=false!g" /data/config/qBittorrent.conf
sed -i "s!WebUI\\\RootFolder=.*!WebUI\\\RootFolder=/data/webui!g" /data/config/qBittorrent.conf

echo "Fixing perms..."
chown qbittorrent:qbittorrent /data \
  /data/config \
  /data/data \
  /data/downloads \
  /data/temp \
  /data/torrents \
  /data/watch \
  /data/webui \
  /media/downloads \
  /media/downloads/torrents \
  /media/downloads/temp
chown -R qbittorrent:qbittorrent "${QBITTORRENT_HOME}" /var/log/qbittorrent

exec yasu qbittorrent:qbittorrent "$@"
