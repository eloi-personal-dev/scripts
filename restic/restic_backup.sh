#!/bin/bash

# Restic Backup Script.
# As it now, this backing up the root user home directory
#
# Version               | 0.4.6
# Author                | Eloi H.
#
# Info                  | Modify the variables to fit your needs,
#                       | you also need to specify your own .restic.env file
#                       | This is a work in progress, run this at your own risk!
#
# License               | MIT

RESET='\033[0m'
YEL='\033[1;33m'
WHITE='\033[1;37m'
RED='\033[1;31m'   # Light Red.
GREEN='\033[1;32m' # Light Green.
STARTGRNH='<strong style="color: limegreen">'
STARTREDH='<strong style="color: red">'
STARTBLUEH='<strong style="color: royalblue">'
ENDFONTHTML="</strong>"
NLHTML="<br>"
HOSTN="$(hostname -f)"
email="your-email@example.com"
subject="Restic System Backup $(date -I)"
subjectfail="Alert!! Restic System Backup $(date -I)"
mailHeader="$HOME/bin/mailheader.txt"
mailFooter="$HOME/bin/mailfooter.txt"
SCRIPTLOC="${HOME}/scripts/restic"
LOGLOC="${HOME}/scripts/restic/logs"
LOGFILE="${HOME}/scripts/restic/logs/restic_backup-temp-work.log"
LOGFILECLEAN="${HOME}/scripts/restic/logs/restic_backup-$(date '+%Y-%m-%d-[time]-%H_%M_%S').log"

# Source the .restic.env file
# shellcheck source=/dev/null
source "$(find "${SCRIPTLOC}" -name ".restic*.env" -type f)"

# Email Notifications
MAILOK() {
  (
    echo "To: ${email}"
    echo "Subject: ${subject}"
    cat "${mailHeader}"
    echo "=== ${HOSTN} ===${NLHTML}${NLHTML}"
    echo "$(date -I) ${STARTBLUEH}${HOSTN}${ENDFONTHTML}${NLHTML}"
    echo "Backup ${STARTGRNH}Complete${ENDFONTHTML}${NLHTML}"
    echo -e "$(cat "$LOGFILE".mail)${NLHTML}"
    echo "Thank you${NLHTML}${NLHTML}"
    echo "=== ${HOSTN} ===${NLHTML}"
    cat "${mailFooter}"
  ) | sendmail -t
}

MAILFAIL() {
  (
    echo "To: ${email}"
    echo "Subject: ${subjectfail}"
    cat "${mailHeader}"
    echo "=== ${HOSTN}  ===${NLHTML}${NLHTML}"
    echo "$(date -I) ${STARTBLUEH}${HOSTN}${ENDFONTHTML}${NLHTML}"
    echo "Backup ${STARTREDH}Failed${ENDFONTHTML}${NLHTML}"
    echo -e "$(cat "$LOGFILE".mail)${NLHTML}"
    echo "Thank you${NLHTML}${NLHTML}"
    echo "=== ${HOSTN} ==="
    cat "${mailFooter}"
  ) | sendmail -t
}

MAILOKPRUNE() {
  (
    echo "To: ${email}"
    echo "Subject: ${subject}"
    cat "${mailHeader}"
    echo "=== ${HOSTN} ===${NLHTML}${NLHTML}"
    echo "$(date -I) ${STARTBLUEH}${HOSTN}${ENDFONTHTML}${NLHTML}"
    echo "Prune ${STARTGRNH}Complete${ENDFONTHTML}${NLHTML}"
    echo "Thank you${NLHTML}${NLHTML}"
    echo "=== ${HOSTN} ===${NLHTML}"
    cat "${mailFooter}"
  ) | sendmail -t
}

MAILFAILPRUNE() {
  (
    echo "To: ${email}"
    echo "Subject: ${subjectfail}"
    cat "${mailHeader}"
    echo "=== ${HOSTN}  ===${NLHTML}${NLHTML}"
    echo "$(date -I) ${STARTBLUEH}${HOSTN}${ENDFONTHTML}${NLHTML}"
    echo "Prune ${STARTREDH}Failed${ENDFONTHTML}${NLHTML}"
    echo -e "$(cat "$LOGFILE".mail)${NLHTML}"
    echo "Thank you${NLHTML}${NLHTML}"
    echo "=== ${HOSTN} ==="
    cat "${mailFooter}"
  ) | sendmail -t
}

MAILOKCHECK() {
  (
    echo "To: ${email}"
    echo "Subject: ${subject}"
    cat "${mailHeader}"
    echo "=== ${HOSTN} ===${NLHTML}${NLHTML}"
    echo "$(date -I) ${STARTBLUEH}${HOSTN}${ENDFONTHTML}${NLHTML}"
    echo "Check ${STARTGRNH}Complete${ENDFONTHTML}${NLHTML}"
    echo "Thank you${NLHTML}${NLHTML}"
    echo "=== ${HOSTN} ===${NLHTML}"
    cat "${mailFooter}"
  ) | sendmail -t
}

MAILFAILCHECK() {
  (
    echo "To: ${email}"
    echo "Subject: ${subjectfail}"
    cat "${mailHeader}"
    echo "=== ${HOSTN}  ===${NLHTML}${NLHTML}"
    echo "$(date -I) ${STARTBLUEH}${HOSTN}${ENDFONTHTML}${NLHTML}"
    echo "Check ${STARTREDH}Failed${ENDFONTHTML}${NLHTML}"
    echo -e "$(cat "$LOGFILE".mail)${NLHTML}"
    echo "Thank you${NLHTML}${NLHTML}"
    echo "=== ${HOSTN} ==="
    cat "${mailFooter}"
  ) | sendmail -t
}

# Exit on failure, pipe failure
set -e -o pipefail

unameOut="$(uname -s)"
case "${unameOut}" in
Linux*) machine=Linux ;;
Darwin*) machine=Mac ;;
CYGWIN*) machine=Cygwin ;;
MINGW*) machine=MinGw ;;
*) machine="UNKNOWN:${unameOut}" ;;
esac

if [[ ${machine} != Linux ]]; then
  echo -e "This script is meant for Linux only"
  exit 1
fi

# Clean up lock if we are killed.
# kills the whole cgroup and all it's subprocesses.
exit_hook() {
  echo "In exit_hook(), being killed" >&2
  jobs -p | xargs kill
  restic unlock
}

trap exit_hook INT TERM

# Log all output
[ -d "$LOGLOC" ] || mkdir -p "$LOGLOC"

# clean old logfile
removeLog() {
  find "$LOGLOC" -maxdepth 1 -type f -name "restic_backup-temp*.log" -exec rm -f {} +
  find "$LOGLOC" -maxdepth 1 -type f -wholename "$LOGFILE.mail" -exec rm -f {} +
}
removeLog

# Log all stdout+stderr
exec > >(tee -a "$LOGFILE") 2>&1

timeStamp() {
  echo -e "${WHITE}$(date +%c)"
}

echo -e "\n${GREEN}[${WHITE} ${GREEN}#${RESET} ${GREEN}]${RESET} ${WHITE}Starting Restic - $(timeStamp)${RESET}\n"

# Start Backup

# Count number if runs
scriptCounter() {
  logCount="$LOGLOC/runs_counter"
  [[ ! -f "$logCount" ]] && echo "0" >"$logCount"
  index=$(<"$logCount")
  printf "%d\n" "$((10#$index + 1))" >"$logCount"
}
scriptCounter

scriptSubCounter() {
  logCount="$LOGLOC/runs_counter"
  [[ ! -f "$logCount" ]] && echo "0" >"$logCount"
  if [ "$(cat "$logCount")" -le 0 ]; then
    echo "0" >"$logCount"
  #   echo "Zeroing"
  #   exit 0
  else
    #   echo "Subtracting"
    index=$(<"$logCount")
    printf "%d\n" "$((10#$index - 1))" >"$logCount"
  fi
}

mailcowCheckPause() {
  # Is mailcow install and running?
  MCPF=$(docker ps -q -f name=nflux_postfix-mailcow_1)
  if [[ -n "${MCPF}" ]]; then
    #  echo "Mailcow present on system"
    (cd /opt/mailcow-dockerized/ && docker-compose pause) >/dev/null 2>&1
  fi
}

mailcowCheckUnpause() {
  # Un-pause Mailcow services
  MCPF=$(docker ps -q -f name=nflux_postfix-mailcow_1)
  if [[ -n "${MCPF}" ]]; then
    # echo "Mailcow present on system"
    (cd /opt/mailcow-dockerized/ && docker-compose unpause) >/dev/null 2>&1
  fi
}

# NOTE start all commands in background and wait for them to finish.
# Reason: bash ignores any signals while child process is executing and thus my trap exit hook is not triggered.
# However if put in subprocesses, wait(1) waits until the process finishes OR signal is received.
# Reference: https://unix.stackexchange.com/questions/146756/forward-sigterm-to-child-in-bash

# Remove locks from other stale processes to keep the automated backup running.
removeLocks() {
  restic unlock &
  wait $!
}

removeLocks &>/dev/null
################################# START #####################################
#
# Execute the Backup
startResticBackup() {

  ############################## VARIABLES #################################
  ## VARIABLES
  # Set all environment variables here

  TAGS="--tag S3.Backup"
  EXCLUDES0="--exclude-file $SCRIPTLOC/.restic_excludes"
  OPTS=" --one-file-system --exclude-caches"
  BACKUP_PATH="/root"

  # How many backups to keep.
  RETENTIONS=" --keep-daily 7 --keep-weekly 4 --keep-monthly 24 --keep-yearly 2"

  # variables end
  ############################## VARIABLES #################################

  # Get list of installed packages
  dpkg --get-selections | cut -f 1 >"/$HOME/installed-software.log"

  # shellcheck disable=SC2086
  restic_Backup="$(restic backup $TAGS $EXCLUDES0 $OPTS $BACKUP_PATH)"
  echo -e "$restic_Backup" &
  wait $!
  restic_Backup_Status=$?
}

startResticPrune() {
  RETENTIONS=" --keep-daily 7 --keep-weekly 4 --keep-monthly 24 --keep-yearly 2"
  # Prune Backups

  # shellcheck disable=SC2086
  restic_Prune="$(restic forget --prune --quiet --group-by "paths,tags" $TAGS $RETENTIONS)"
  echo -e "$restic_Prune" &
  wait $!
  restic_Prune_Status=$?
}
###########################################################################
#

resticSnapshotLatest() {
  echo -e ""
  echo -e "${GREEN}"
  restic snapshots | head -n -1
  echo -ne "${RESET}"
}

resticForget() {
  echo -e ""
  echo -e "${GREEN}"
  restic snapshots -v
  echo -ne "${RESET}"
}

cleanUpLog() {
  sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" "$LOGFILE" >"$LOGFILECLEAN"
  sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" "$LOGFILE" >"$LOGFILE.mail"
  find "$LOGLOC"/ -maxdepth 1 -type f -name "*.log" -mtime +90 -exec rm -f {} +
}

backupCheck() {
  if [ "$restic_Backup_Status" == 0 ]; then
    echo -e "\n${WHITE}Backup:${GREEN} Complete${RESET}\n"
    MAILOK
  else
    echo -e "\n${WHITE}Backup:${RED} Failed${RESET}\n"
    MAILFAIL
  fi
}

# shellcheck disable=SC2086
backupRestoreTest() {
  DAYSOLD=1
  TESTFILELOC="/$HOME/scripts/restic/TEST-RESTIC-RESTORE"
  # what is the snapshot id of the backup from $DAYSOLD days ?
  SNAPSHOTNR="$(restic snapshots | grep "$HOSTN" | tail -n ${DAYSOLD} | head -n 1 | awk '{print $1;}')"
  # Dummy File to test backups periodically
  STATIC_TESTFILE="${TESTFILELOC}/original/Bob_Marley-Stir_It_Up.txt"
  SNAP_TESTFILE="${TESTFILELOC}/snapshot/Bob_Marley-Stir_It_Up.txt"
  restic_restoretest=$(restic restore "${SNAPSHOTNR}" --include ${STATIC_TESTFILE} --target ${SNAP_TESTFILE})
  echo -e "$restic_restoretest" &
  wait $!
  ANY_DIFFERENCE="$(diff -q "$STATIC_TESTFILE" "$SNAP_TESTFILE")"

  if [[ "${#ANY_DIFFERENCE}" -ne 0 ]]; then
    MAILFAILCHECK
  fi
}

pruneCheck() {
  if [ "$restic_Prune_Status" == 0 ]; then
    echo -e "\n${WHITE}Backup Prune:${GREEN} Complete${RESET}\n"
    # MAILOKPRUNE
  else
    echo -e "\n${WHITE}Backup Prune:${RED} Failed${RESET}\n"
    MAILFAILPRUNE
  fi
}

resticCheck() {
  restic check --cleanup-cache
  restic_Check_Status=$?
}

resticCheckRead() {
  restic check --cleanup-cache --read-data --quiet
  restic_Check_Status=$?
}

resticCheckEmail() {
  if [ "$restic_Check_Status" == 0 ]; then
    echo -e "\n${WHITE}Restic Check:${GREEN} Complete${RESET}\n"
    MAILOKCHECK
  else
    echo -e "\n${WHITE}Restic Check:${RED} Failed${RESET}\n"
    MAILFAILCHECK
  fi
}

resticStats() {
  echo -e "${YEL}"
  restic stats --mode raw-data
  echo -e
  restic stats | grep --color "Total" | awk '{$1=$1};1'
  echo -e
  restic stats -v
  echo -e
  echo -ne "${RESET}"
}

case $1 in
backup)
  echo -e "\n${GREEN}######################################################################\n"
  mailcowCheckPause
  startResticBackup
  mailcowCheckUnpause
  resticStats
  echo -e "\n${GREEN}######################################################################\n"
  timeStamp
  cleanUpLog
  backupCheck
  scriptSubCounter
  ;;
check)
  echo -e "\n${GREEN}######################################################################\n"
  resticCheck
  startResticPrune
  pruneCheck
  echo -ne "${GREEN}"
  resticCheckRead
  resticStats
  echo -e "\n${GREEN}######################################################################\n"
  timeStamp
  cleanUpLog
  scriptSubCounter
  resticCheckEmail
  ;;
backup-check)
  if [ "$(cat "$logCount")" -le 10 ]; then
    echo -e "\n${GREEN}######################################################################\n"
    mailcowCheckPause
    startResticBackup
    mailcowCheckUnpause
    resticStats
    echo -e "\n${GREEN}######################################################################\n"
    timeStamp
    cleanUpLog
    backupCheck
  else
    resticCheck
    startResticPrune
    pruneCheck
    resticCheckRead
    backupRestoreTest
    timeStamp
    cleanUpLog
    resticCheckEmail
    echo "0" >"$logCount"
  fi
  ;;
prune)
  startResticPrune
  timeStamp
  cleanUpLog
  scriptSubCounter
  pruneCheck
  ;;
snapshots | snapshot)
  echo -e "\n${GREEN}######################################################################\n"
  resticSnapshotLatest
  resticStats
  timeStamp
  cleanUpLog
  scriptSubCounter
  echo -e "\n${GREEN}######################################################################\n"
  ;;
forget)
  echo -e "\n${GREEN}######################################################################\n"
  resticForget
  echo ""
  while true; do
    read -rp "Delete snapshot? [Y/n]: " yn
    case $yn in
    [Yy]*)
      read -rp "Enter snapshot Name: " snapshotname
      restic forget "$snapshotname"
      scriptSubCounter
      echo -e "\n${GREEN}######################################################################\n"
      break
      ;;
    [Nn]*)
      scriptSubCounter
      echo -e "\n${GREEN}######################################################################\n"
      exit 0
      ;;
    *)
      echo "Please answer yes or no."
      ;;
    esac
  done
  ;;
diff)
  echo -e "\n${GREEN}######################################################################\n"
  resticSnapshotLatest
  echo ""
  while true; do
    read -rp "Diff snapshot? [Y/n]: " yn
    case $yn in
    [Yy]*)
      read -rp "Enter Snapshot 1: " snapshotname1
      read -rp "Enter Snapshot 2: " snapshotname2
      restic diff "$snapshotname1" "$snapshotname2"
      scriptSubCounter
      echo -e "\n${GREEN}######################################################################\n"
      break
      ;;
    [Nn]*)
      scriptSubCounter
      echo -e "\n${GREEN}######################################################################\n"
      exit 0
      ;;
    *)
      echo "Please answer yes or no."
      ;;
    esac
  done
  ;;
TestBackupFile)
  echo -e "\n${GREEN}######################################################################\n"
  backupRestoreTest
  ;;
*)
  echo -e "\n${YEL}######################################################################\n"
  #shellcheck disable=SC2128
  echo -e "\n${WHITE}Usage: ${GREEN}$(basename "$BASH_SOURCE")${WHITE} [${GREEN} backup check backup-check prune snapshots forget diff ${WHITE}]\n"
  echo -e "\n${YEL}######################################################################\n"
  ;;
esac
