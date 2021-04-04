#!/usr/bin/env bash
#
# 1. Save locally, chmod +x <file>
#
# 2. Add a cron entry to run it, for example:
#   30 9 * * * /Users/dougb/MagicPower/MagicPowerAlert.sh
#
# 3. Or, run frequently but set the muting and inactivity vars
#   */30 * * * * /Users/dougb/MagicPower/MagicPowerAlert.sh
#
#   MUTE_CONSECUTIVE_ALERTS_HOURS=4
#   INACTIVITY_THRESHOLD_MINS=5

# You can change the default (20) threshold by passing a value as the first argument to the script
THRESHOLD="${1:-20}"

# Set to mute consecutive alerts for a period of minutes. Makes it practical to schedule
# MagicPowerAlert to run frequently, say every 30 minutes. Really, two alerts per day are
# probably enough of a reminder. So a good value is maybe 4 hours.
MUTE_CONSECUTIVE_ALERTS_HOURS=4

# Inactivity detection. If user is afk, don't continue and possibly spam the desktop with alerts.
# For example, no alerts during the night when running other automated tasks.
INACTIVITY_THRESHOLD_MINS=5

# You can change the message, if coffee is not your thing
MESSAGE="Get a coffee and charge:\n"

# set to 1, creates a log file for debugging. Log file is ./MagicPowerAlert.sh.log
LOGFILE=0

# Change nothing below here
messages=()

# Crude but simple logger to file.
function logger() {
    if [[ $LOGFILE -eq 1 ]]; then
        echo "$(date) $1" >> ${BASH_SOURCE[0]}.log
    fi
}

# Handler cli args. Strip a percent sign in case the user supplied one
THRESHOLD="${THRESHOLD/\%/}"
if [[ "$THRESHOLD" == "status" ]]; then
    getStatus="true"
elif [[ "$THRESHOLD" -lt 1 ]] || [[ "$THRESHOLD" -gt 100 ]]; then
    echo "[!] Alert threshold must be between 1% and 100%" >&2
    exit 1
else
    getStatus="false"
fi

# Check for inactivity, exit if the user is away from keyboard. Skip if this is a cli status check.
IOREG_IDLE=$(/usr/sbin/ioreg -k HIDIdleTime -a -r)
inactivity=$(/usr/bin/xmllint --xpath "
                /plist/
                  array/
                    dict/
                      key[.='HIDIdleTime']/
                      following-sibling::*[1]/
                        text()" - 2>/dev/null <<< "$IOREG_IDLE")
INACTIVITY_SECONDS=$(( $inactivity / 1000000000 ))
INACTIVITY_MINUTES=$(( $INACTIVITY_SECONDS / 60 ))

if [[ $INACTIVITY_MINUTES -ge $INACTIVITY_THRESHOLD_MINS && $getStatus != "true" ]]; then
    logger "skip because of inactivity for $INACTIVITY_MINUTES m [threshold is $INACTIVITY_THRESHOLD_MINS m]"
    exit 0
fi

# Clear out possible mute alerts file if expired, unless it's a cli status check.
muteAlertsFileName="${BASH_SOURCE[0]}.mute"

if [[ -f $muteAlertsFileName && $getStatus != "true" ]]; then
    fileAgeInSeconds=$(($(date +%s) - $(stat -t %s -f %m -- "$muteAlertsFileName")))
    fileAgeInMinutes=$((fileAgeInSeconds / 60))
    fileAgeInHours=$((fileAgeInMinutes / 60))

    if [[ $fileAgeInHours -ge $MUTE_CONSECUTIVE_ALERTS_HOURS ]]; then
        logger "removing file $muteAlertsFileName"
        rm $muteAlertsFileName
    fi

    if [[ $fileAgeInHours -lt $MUTE_CONSECUTIVE_ALERTS_HOURS ]]; then
        logger "skip because muting active. file $muteAlertsFileName has age $fileAgeInMinutes m"
        exit 0
    fi
fi


# Gather XML data about devices reporting a 'BatteryPercent'
IOREG=$(/usr/sbin/ioreg -r -a -k BatteryPercent 2>/dev/null)

# Count how many devices we found
NUM_DEVICES=$(/usr/bin/xmllint --xpath "
                count(//plist/array/dict)" - 2>/dev/null <<< "$IOREG")

# Exit here if no devices found
[[ $NUM_DEVICES == '' ]] && exit

# Build an array of their device names
declare -a DEVICES
for device_num in $(seq 1 "$NUM_DEVICES"); do
    if name=$(/usr/bin/xmllint --xpath "
                /plist/
                array/
                    dict[$device_num]/
                    key[.='Product']/
                        following-sibling::*[1]/
                        text()" - 2>/dev/null <<< "$IOREG"); then
            DEVICES+=("$name")
    fi
done

for index in ${!DEVICES[*]}; do
    device=${DEVICES[$index]}
    powerValue=$(/usr/bin/xmllint --xpath "
                    /plist/
                      array/
                        dict/
                          key[.='Product']/
                            following-sibling::*[1][text()=\"$device\"]/
                          ../
                            key[.='BatteryPercent']/
                              following-sibling::*[1]/
                                text()" - 2>/dev/null <<< "$IOREG")
    statusFlag=$(/usr/bin/xmllint --xpath "
                    /plist/
                      array/
                        dict/
                          key[.='Product']/
                            following-sibling::*[1][text()=\"$device\"]/
                          ../
                            key[.='BatteryStatusFlags']/
                              following-sibling::*[1]/
                                text()" - 2>/dev/null <<< "$IOREG")
    if [[ $statusFlag == 3 ]]; then
        status=" (charging)"
    else
        status=""
    fi
    int_re='^[0-9]+$'
    if [[ $powerValue =~ $int_re ]] ; then
        if [[ $getStatus == "true" ]]; then
            messages[$index]="$device at $powerValue%$status"
        fi
        if [[ $powerValue -le $THRESHOLD ]]; then
            messages[$index]="$device at $powerValue%"
        fi
    fi
done

len=${#messages[@]}
if (( "$len" > 0 )); then

    if [[ -z $MESSAGE ]]; then
            message="Get a coffee and charge:\n"
    else
            message=$MESSAGE
    fi

    if [[ $getStatus == "true" ]]; then
        for index in ${!messages[*]}; do
            echo "${messages[$index]}"
        done
    else
        for index in ${!messages[*]}; do
            message="$message\n\t${messages[$index]}"
            logger "alerting with ${messages[$index]}"
        done

        # osascript is blocking, so create mute file here to signal subsequent runs to skip
        # consecutive alerts.
        touch $muteAlertsFileName
        logger "created file $muteAlertsFileName"

        # Interestingly, this osascript process only last for about 60s. even when it is still
        # visible as a window alert. So we can't just grep for the process and use that method
        # to mute consecutive alerts.
        /usr/bin/osascript -e "
            tell application \"System Events\"
                activate
                display alert \"$message\"
            end tell
        " >/dev/null 2>&1
    fi
fi
