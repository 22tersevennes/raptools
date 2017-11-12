#!/bin/bash

[ ! -z "$DEBUG" ] && set -x

HOST=fraise
USER=pi

KEEP=5

LOCALDIR=$(dirname $(realpath $0))

BACKUP_FILE="/home/pi/domoticz/domoticz.db"
BACKUP_DIR="/home/pi/.credentials /home/pi/domoticz /home/pi/google-calendar-reader /etc"

cd "$LOCALDIR/files"

for source in "$BACKUP_FILE"; do
    source_fn=$(basename $source)
    bck=$(ls -r "$source_fn".* 2> /dev/null)
    for dbf in $bck; do
    	ext="${dbf##*.}"
    	filename="${dbf%.*}"
    	if [ $ext -ge $KEEP ]; then
	    rm -f "$dbf"
    	else
	    next=$(( $ext + 1 ))
	    mv "$dbf" "$filename.$next"
    	fi
    done
    scp "$USER@$HOST:$source" "$source_fn.1" > /dev/null 2>&1
done

cd $LOCALDIR
for dir in $BACKUP_DIR; do
    #echo rsync -av $USER@$HOST:$dir dirs/ 
    rsync -av $USER@$HOST:$dir dirs/ > /dev/null 2>&1
done

exit
