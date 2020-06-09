#!/usr/bin/env bash
#
# 1. Save locally, chmod +x <file>
#
# 2. Add a cron entry to run it, for example:
#   30 9 * * * /Users/dougb/MagicPower/MagicPowerAlert.sh
#

# You can change the threshold
THRESHOLD=20

# You can change the message, if coffee is not your thing
MESSAGE="Get a coffee and charge:\n"

# Change nothing below here
messages=()

# Gather XML data about devices reporting a 'BatteryPercent'
IOREG=$(/usr/sbin/ioreg -r -a -k BatteryPercent 2>/dev/null)

# Count how many devices we found
NUM_DEVICES=$(/usr/bin/xmllint --xpath "
                count(//plist/array/dict)" - 2>/dev/null <<< "$IOREG")

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
    int_re='^[0-9]+$'
    if [[ $powerValue =~ $int_re ]] ; then
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

    for index in ${!messages[*]}; do
        message="$message\n\t${messages[$index]}"
    done

    /usr/bin/osascript -e "
        tell application \"System Events\"
            activate
            display alert \"$message\"
        end tell
    " >/dev/null 2>&1
fi
