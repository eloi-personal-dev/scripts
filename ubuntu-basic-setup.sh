#!/bin/bash

#
# Author        :Eloi H.
# email         :support@it-ed.com
# Description   :Script to configure a basic ubuntu server.
#                Thanks to the internet for making this possible!
# License       :MIT

# Colors
RESET='\033[0m'
YEL='\033[1;33m'
WHITE='\033[1;37m'
#GRAY='\033[0;37m'
RED='\033[1;31m'
GREEN='\033[1;32m'

header() {
  clear
  clear
  echo -e "${GREEN}###################################################################################${RESET}\\n"
}

header_yel() {
  clear
  clear
  echo -e "${YEL}###################################################################################${RESET}\\n"
}

header_red() {
  clear
  clear
  echo -e "${RED}###################################################################################${RESET}\\n"
}

progressBarLong() {
  BAR='o O o O o O o O o O o O o O o O o O o O'
  for i in {1..45}; do
    echo -ne "${YEL}\r${BAR:0:$i}${RESET}" # print $i chars of $BAR from 0 position
    sleep .1                               # wait 100ms between "frames"
  done
}

progressBar() {
  BAR='o O o O o O o O o O o O'
  for i in {1..20}; do
    echo -ne "${YEL}\r${BAR:0:$i}${RESET}" # print $i chars of $BAR from 0 position
    sleep .1                               # wait 100ms between "frames"
  done
  echo
}

progressITED() {
  BAR="... Support IT-ED.com ..."
  echo -e "\n${WHITE}Un moment SVP...\n"
  for i in {1..28}; do
    echo -ne "${YEL}\r${BAR:0:$i}${RESET}" # print $i chars of $BAR from 0 position
    sleep .1                               # wait 100ms between "frames"
  done
  echo
  echo -e "\n${GREEN}Prêt${RESET}"
  echo
}

progressITEDFin() {
  BAR="... Support IT-ED.com ..."
  echo -e "\n${WHITE}Un moment SVP...\n"
  for i in {1..28}; do
    echo -ne "${YEL}\r${BAR:0:$i}${RESET}" # print $i chars of $BAR from 0 position
    sleep .1                               # wait 100ms between "frames"
  done
  echo
  echo -e "\n${GREEN}Terminé${RESET}"
  echo
}

# Variables

# Set the locale
export LANG="en_US.UTF-8"
export LC_ALL="C"

# shellcheck disable=SC2002
adminUser=$(cat /etc/passwd | grep 1000 | cut -f1 -d ":")

installDefaults() {
  ## Refresh the package lists
  apt-get update >/dev/null 2>&1

  ## Remove conflicting utilities
  /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' purge snapd ntp openntpd snap lxd lxc bind bind9 bluez docker docker-engine docker.io containerd runc

  ## Update
  /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' dist-upgrade

  ## Install common system utilities
  REQPKGS=(apt-transport-https
    bash-completion
    ca-certificates
    curl
    dialog
    dos2unix
    dfc
    dnsutils
    git
    htop
    nano
    net-tools
    ifupdown
    pigz
    software-properties-common
    sudo
    unzip
    zip
    apt-listchanges
    wget
    man-db
    manpages-posix
  )

  for pkg in "${REQPKGS[@]}"; do
    if ! dpkg-query -W -f'${Status}' "$pkg" 2>/dev/null | grep -q "ok installed"; then
      #if ! command -v "$pkg" &> /dev/null; then
      /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' install "$pkg"
      printf "%b#%b%b %s\n" "${GREEN}" "${RESET}" "${WHITE}" "$pkg"
    fi
  done
  # shellcheck disable=SC2059
  printf "%b#%b%b Have been Installed\n" "${GREEN}" "${RESET}" "${WHITE}"
}

initSetup() {
  sed -i 's/ENABLED=1/ENABLED=0/g' "/etc/default/motd-news"
  echo 'export HISTIGNORE="shutdown *:rm *:&:[ ]*:exit:ls:bg:fg:history:zpool destroy *:zfs destroy *:wipefs *"' >>~/.bashrc
  sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' "/root/.bashrc"
  sed -i 's|\$ '"'"'|n\$ '"'"'|g' "/root/.bashrc"
  sed -i 's/#force_color_prompt=yes/force_color_prompt=yes/g' "/home/$adminUser/.bashrc"
  sed -i 's|\$ '"'"'|n\$ '"'"'|g' "/home/$adminUser/.bashrc"

  cat <<EOF >>"/etc/sudoers.d/$adminUser"
Defaults:$adminUser timestamp_timeout=60
EOF
}

# shellcheck disable=SC2120,SC2154
rootAliases() {
  cat <<EOF >>"/root/.bash_aliases"

# ITED
# Safety - prevent deletion of / or prompt if deleting more than 3 files at a time
alias rm='rm -I --preserve-root'

# Safe Guards
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'
alias rm='rm -Ri'

# File Permissions
alias stat_num='stat -c "%A %a %n"'
lso() { ls -l "$@" | awk '{k=0;for(i=0;i<=8;i++)k+=((substr($1,i+2,1)~/[rwx]/)*2^(8-i));if(k)printf(" %0o ",k);print}'; }


alias ll=' ls -lah --color=auto --group-directories-first'
alias mkdir='mkdir -pv'
alias nn='nano'

# SystemD
alias sdlist='systemctl list-units --type service'
alias sdlist-enabled='systemctl list-unit-files --state=enabled'
alias sdlist-masked='systemctl list-unit-files --state=masked'
alias ssdr='systemctl daemon-reload'

# journal
alias jctl1='journalctl -p warning -S  -20m'
alias jctl2='journalctl -p 3 -xb'

alias aptupdate='apt update && apt list --upgradable'


# Remove pattern in history

histdelete() { [[ -z "$1" ]] && echo "Enter grep patttern!" || for ln in $(history | grep "$1" | cut -f2 -d' ' | tac); do history -d $ln; done; }
# ITED
EOF
}

# shellcheck disable=SC2120
userAliases() {
  cat <<EOF >>"/home/$adminUser/.bash_aliases"

# ITED
# Safety - prevent deletion of / or prompt if deleting more than 3 files at a time
alias rm='rm -I --preserve-root'

# Safe Guards
alias chown='chown --preserve-root'
alias chmod='chmod --preserve-root'
alias chgrp='chgrp --preserve-root'
alias mv='mv -i'
alias cp='cp -i'
alias ln='ln -i'
alias rm='rm -Ri'

alias stat_num='stat -c "%a %n"'

alias ll=' ls -lah --color=auto --group-directories-first'
alias mkdir='mkdir -pv'
alias nn='nano'

# SystemD
alias sdlist='sudo systemctl list-units --type service'
alias sdlist-enabled='sudo systemctl list-unit-files --state=enabled'
alias sdlist-masked='sudo systemctl list-unit-files --state=masked'
alias ssdr='sudo systemctl daemon-reload'

# journal
alias jctl1='sudo journalctl -p warning -S  -20m'
alias jctl2='sudo journalctl -p 3 -xb'
alias aptupdate='sudo apt update && sudo apt list --upgradable'


fix_perms_dir() { find "$1" -type d -exec chmod 755 {} +; }
fix_perms_file() { find "$1" -type f -exec chmod 644 {} +; }


histdelete() { [[ -z "$1" ]] && echo "Enter grep patttern!" || for ln in $(history | grep "$1" | cut -f2 -d' ' | tac); do history -d $ln; done; }
# ITED
EOF
}

rootNanoConfig() {
  cat <<EOF >"/root/.nanorc"
set softwrap
set constantshow
set tabstospaces
bind ^Z suspend main

# BACKUPS
#set backup
#set backupdir "~/.nano/"

set titlecolor green,black
set numbercolor yellow
set statuscolor green,black
set keycolor green

include "/usr/share/nano/*.nanorc"
EOF
}

userNanoConfig() {
  cat <<EOF >"/home/$adminUser/.nanorc"
set softwrap
set constantshow
set tabstospaces
bind ^Z suspend main

# BACKUPS
#set backup
#set backupdir "~/.nano/"

set titlecolor green,black
set numbercolor yellow
set statuscolor green,black
set keycolor green

include "/usr/share/nano/*.nanorc"
EOF
}

timezoneSetup() {
  ## Set Timezone, empty = set automatically by ip
  this_ip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
  timezone="$(curl "https://ipapi.co/${this_ip}/timezone")"
  if [ "$timezone" != "" ]; then
    echo "Found $timezone for ${this_ip}"
    timedatectl set-timezone "$timezone"
  else
    echo "WARNING: Timezone not found for ${this_ip}, set to UTC"
    timedatectl set-timezone UTC
  fi

  sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen &&
    echo -e 'LANG="en_US.UTF-8"' >/etc/default/locale &&
    dpkg-reconfigure --frontend=noninteractive locales &&
    update-locale LANG=en_US.UTF-8
}

tcpTuning() {
  ## Enable TCP BBR congestion control
  cat <<EOF >/etc/sysctl.d/99-kernel-bbr.conf
# it-ed.com
# TCP BBR congestion control
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
  cat <<EOF >/etc/sysctl.d/99-tcp-fastopen.conf
# it-ed.com
# TCP fastopen
net.ipv4.tcp_fastopen=3
EOF

  cat <<EOF >/etc/sysctl.d/99-net.conf
# it-ed.com
net.core.netdev_max_backlog=8192
net.core.optmem_max=8192
net.core.rmem_max=16777216
net.core.somaxconn=8151
net.core.wmem_max=16777216
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.log_martians = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.default.log_martians = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.ip_local_port_range=1024 65535
net.ipv4.tcp_base_mss = 1024
net.ipv4.tcp_challenge_ack_limit = 999999999
net.ipv4.tcp_fin_timeout=10
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_keepalive_time=240
net.ipv4.tcp_limit_output_bytes=65536
net.ipv4.tcp_max_syn_backlog=8192
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_rfc1337=1
net.ipv4.tcp_rmem=8192 87380 16777216
net.ipv4.tcp_sack=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_syn_retries=3
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 0
net.ipv4.tcp_wmem=8192 65536 16777216
net.netfilter.nf_conntrack_generic_timeout = 60
net.netfilter.nf_conntrack_helper=0
net.netfilter.nf_conntrack_max = 524288
net.netfilter.nf_conntrack_tcp_timeout_established = 28800
net.unix.max_dgram_qlen = 4096
EOF

  cat <<EOF >/etc/sysctl.d/99-swap.conf
# it-ed.com
# Bugfix: high swap usage with low memory usage
vm.swappiness=10
EOF
}

# shellcheck disable=SC2086
netplanStaticIP() {
  # Create Backup
  newNetPlan="/etc/netplan/"
  defaultNetPlan=$(find /etc/netplan/ -name "00-installer-config.yaml")
  /bin/cp -rf "${defaultNetPlan}" "/etc/netplan/netplan-default-$(date -I).yaml.backup"
  # Retrieves NIC Information
  echo -e "\n\n${YEL}$(ip -o link show | awk '{print $2}')${RESET}"
  # Network Configuration
  echo
  read -e -rp "$(echo -e ${WHITE}Enter Network Interface ^ [e.g. ${YEL}ens18${WHITE}]:${RESET}) " iface
  echo
  read -e -rp "$(echo -e ${WHITE}Enter Static IP in CIDR notation [e.g. ${YEL}10.10.10.22/24${WHITE}]:${RESET}) " staticip
  echo
  read -e -rp "$(echo -e ${WHITE}Enter the Gateway ip [e.g. ${YEL}10.10.10.22${WHITE}]:${RESET}) " gateway
  echo
  read -e -rp "$(echo -e ${WHITE}Enter DNS nameserver\(s\) comma seperated [e.g. ${YEL}10.10.10.1,10.10.10.53${WHITE}]:${RESET}): " nameserversip
  echo
  read -e -rp "$(echo -e ${WHITE}Enter the Domain search [e.g. ${YEL}it-ed.com${WHITE}]:${RESET}) " domainsearch
  echo

  cat <<EOF >$newNetPlan
network:
  version: 2
  renderer: networkd
  ethernets:
    $iface:
      dhcp4: false
      dhcp6: false
      addresses:
        - $staticip
      routes:
        - to: default
          via: $gateway
      nameservers:
          addresses: [$nameserversip]
          search: [$domainsearch]
EOF

  progressBar
  echo
  echo
  echo -e "${GREEN}[${WHITE} ${GREEN}#${RESET} ${GREEN}]${RESET} ${WHITE}Done... ${RESET}\n"
  echo -e "${GREEN}[${WHITE} ${GREEN}#${RESET} ${GREEN}]${RESET} ${WHITE}Setting Static IP...${RESET}\n"
  sleep .7s
  echo -e "${GREEN}$(cat $newNetPlan)${RESET}\n"
  echo -e "${GREEN}[${WHITE} ${GREEN}#${RESET} ${GREEN}]${RESET} ${WHITE}Static IP Complete${RESET}\n"
  echo -e "${YEL}[${WHITE} ${YEL}#${RESET} ${YEL}]${RESET} ${WHITE}Reboot Required${RESET}\n"
}

applyNetPlan() {
  netplan apply
}

ntpSetup() {
  cat <<EOF >/etc/systemd/timesyncd.conf
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free
#  Software Foundation; either version 2.1 of the License, or (at your option)
#  any later version.
#
# Entries in this file show the compile time defaults. Local configuration
# should be created by either modifying this file, or by creating "drop-ins" in
# the timesyncd.conf.d/ subdirectory. The latter is generally recommended.
# Defaults can be restored by simply deleting this file and all drop-ins.
#
# See timesyncd.conf(5) for details.

[Time]
NTP=0.ca.pool.ntp.org 1.ca.pool.ntp.org 2.ca.pool.ntp.org
FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org 3.pool.ntp.org
#RootDistanceMaxSec=5
#PollIntervalMinSec=32
#PollIntervalMaxSec=2048
EOF

  /usr/bin/systemctl restart systemd-timesyncd.service
  /usr/bin/systemctl status systemd-timesyncd.service
  echo
  timedatectl status
  echo -e "\n${GREEN}$(date)${RESET}\n"
}

mainMenu() {
  header
  while true; do
    echo -e "${WHITE}#${RESET} ${GREEN}Debian Setup Main Menu${RESET}\n"
    echo -e "${WHITE}Here are the choices...${RESET}\n"
    echo -e " ${GREEN}[${WHITE} [1] ${GREEN}] ${GREEN} [${WHITE} Default Programs ${GREEN}]  ${WHITE}Install Basic Linux Applications ${RESET} "
    echo -e " ${GREEN}[${WHITE} [2] ${GREEN}] ${GREEN} [${WHITE} Set Static IP ${GREEN}]  ${WHITE}Staic IP ${RESET} "
    echo -e " ${GREEN}[${WHITE} [3] ${GREEN}] ${GREEN} [${WHITE} Exit ${GREEN}] \n"
    echo -ne "${WHITE}Select Option ${GREEN}[${WHITE} Number ${GREEN}]${RESET}: "
    read -r menu
    case $menu in
    1)
      header
      echo -e "${GREEN}[${WHITE} ${GREEN}#${RESET} ${GREEN}]${RESET} ${WHITE}Installing default programs...${RESET}\n"
      progressBar
      installDefaults
      timezoneSetup
      ntpSetup
      initSetup
      rootAliases
      rootNanoConfig
      userNanoConfig
      userAliases
      find "/home/$adminUser" -user root -exec chown "$adminUser":"$adminUser" {} \;
      # cleanup
      ## Remove no longer required packages and purge old cached updates
      /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' autoremove
      /usr/bin/env DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' autoclean
      ;;
    2)
      header
      echo -e "${GREEN}[${WHITE} ${GREEN}#${RESET} ${GREEN}]${RESET} ${WHITE}Setting Static IP...${RESET}\n"
      netplanStaticIP
      applyNetPlan
      echo -e "${RED}#${RESET} ${WHITE}Please Reboot. Reboot ${RED}Required!${RESET} \n"
      ;;
    3)
      header
      echo -e "${GREEN}[${WHITE} ${GREEN}#${RESET} ${GREEN}]${RESET} ${WHITE}Good-Bye...${RESET}\n"
      progressITEDFin
      echo -e ""
      break
      echo -e "${RED}#${RESET} ${WHITE}Please Reboot. Reboot Required! \n"
      exit 0
      ;;
    *)
      header_red
      echo -e "${RED}#${RESET} ${WHITE}Enter at least one option. \n"
      ;;
    esac
  done
}

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}#${RESET} ${WHITE}Please run as ${RED}root${RESET}\n"
  exit
fi

progressITED

mainMenu
