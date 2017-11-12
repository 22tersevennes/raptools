#!/bin/bash

DEBUG=${DEBUG=}


[ "$DEBUG" = "YES" ] && set -x

BASE="/var/tmp/mon-temp"
[ ! -d "$BASE" ] && mkdir "$BASE"

HALERT="${BASE}/.alert.date"
DB="${BASE}/histo"
DB_RND="${BASE}/histo.rnd"
DB_KEEP="4"
MAXLINE=$(( 12 * 24 )) # One day

MAX=60
ALERT=50
ALERT_MSG_INTERVAL=1800

TEMP=$(cat /sys/class/thermal/thermal_zone0/temp)
TEMP=$(($TEMP/1000)) # °C
DATE=$(date +%s)
DATE_S=$(date -u -d @${DATE} --rfc-3339=second)
CALERT="  "

function rotate
{
    set -x
    local _LINE=$(wc -l "$DB" | cut -f1 -d' ')
    [ $_LINE -ge $MAXLINE ] &&	{
	for ((IDX=DB_KEEP;IDX>0;IDX--)); do
	    local NEXT=$(( $IDX + 1 ))
	    echo "$IDX ->  $NEXT " 
	    [ -f "$DB.$IDX" ] && mv "$DB.$IDX" "$DB.$NEXT"
	done
	 [ -f "$DB" ] && mv "$DB" "$DB.1"
    }
    set +x
}


function sendalert
{
    local _DATE=$(date +%s)
    local _PDATE=0
    [ -f "$HALERT" ] && _PDATE=$(cat "$HALERT")
    delta=$(( $_DATE - $_PDATE ))
    [ $delta -ge $ALERT_MSG_INTERVAL ] && {
	echo $(date +%s) >  "$HALERT"
	curl -G --url "https://smsapi.free-mobile.fr/sendmsg?user=18673094&pass=R8u1NE4kpMEaoS" --data-urlencode "msg=$1" 
    }
}

[ $TEMP -gt $ALERT ] && CALERT='--'
[ $TEMP -gt $MAX   ] && CALERT='**'

rotate

echo "$CALERT|$DATE|$DATE_S|$TEMP" >> "$DB"

sendalert "PLEX ($DATE_S) Temperature : $TEMP °C"

exit 0



