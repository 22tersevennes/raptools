#!/bin/bash
#
# Batch mode :
#     $ ./rsync-useed.sh
# Interactive mode : 
#     $ INTERACTIVE=YES ./rsync-useed.sh 
#
#set -x
#RSYNC="rsync"
RSYNC="/storage/.kodi/addons/network.backup.rsync/bin/rsync"
APP=$(basename $0)
APPDIR=$(dirname `realpath $0`)
APPNAME=${APP%.*}

trap ctrl_c INT

ctrl_c() {
  fn_log "Interrupted by CTRL-C"
  fn_pid_clear
}

DEBUG=${DEBUG:}

# ------------------------------------------------------
fn_log() {
   date=$(date +'%F %R')
   _pid=$(printf "[$APPNAME:%6d]" $$)
   echo "$date $_pid $1" >> "$LOG"
   [ "$IS_INTERACTIVE" == "YES" ] && echo $APPNAME": "$1
   [ "$DEBUG" == "YES" ] && logger $$
}

PID="$APPDIR/$APPNAME.pid"
LOG="$APPDIR/$APPNAME.log"

IS_INTERACTIVE=""
[ -n "$SSH_TTY" ] && {
   IS_INTERACTIVE="YES"
   fn_log "Interactive mode"
}

OPTS=${OPTS:}

USER=$( cat .rsync-useed.pwd | cut -d: -f1 )
PASS=$( cat .rsync-useed.pwd | cut -d: -f2 )
fn_log 'user '$USER', password ------ '

HOST="fantasia.useed.fr"
SUBDIR=${1:-}
PROGRESS="-quiet"
[ "$IS_INTERACTIVE" == "YES" ] && PROGRESS="--progress"
RSYNCOPT_KEEP="$PROGRESS --remove-source-files -avz -h $OPTS $USER@$HOST::$USER/plex/ /storage/useed/plex/"

# ------------------------------------------------------
fn_pid_check() {                                        
   [ -f "$PID" ] && {                                      
      read pid < "$PID"                                     
      fn_log "Seems to be runnning, PID=$pid"          
      ps afxwww | grep ${APPNAME} |  grep "^ *${pid}"       
      process=$(ps afxwww | grep ${APPNAME} |  grep "^ *${pid}" )
      fn_log "Aborting..."
      exit 1
   }
   echo $$ > "$PID"
}                                                       

# ------------------------------------------------------
fn_pid_clear() {                                        
   rm -f "$PID"
}                                                       

# ------------------------------------------------------
fn_rsync() {
   ROPT="$*"
   fn_pid_check
   fn_log "Running > RSYNC_PASSWORD=\"++++++++\" $RSYNC $ROPT"                   
   #fn_log  "Starting USeed synchro"
   start=$( date +%s )
   if [ "$IS_INTERACTIVE" == "YES" ]; then
      RSYNC_PASSWORD="$PASS" $RSYNC $ROPT
   else
      #rsynclog=$($RSYNC $ROPT)           
      RSYNC_PASSWORD="$PASS" $RSYNC $ROPT           
      #fn_log "rsync  log - 8< -------------"  
      #fn_log "$rsynclog"                      
      #fn_log "- >8 -------------"             
  fi
  stop=$( date +%s )
  secs=$(( stop - start ))
  fn_pid_clear
  tms=$( printf '%02dh:%02dm:%02ds' $(($secs/3600)) $(($secs%3600/60)) $(($secs%60)) )
  fn_log "Sync. done [$tms]."
}                                     

# ------------------------------------------------------
#
fn_rsync $RSYNCOPT_KEEP
#
exit 0
