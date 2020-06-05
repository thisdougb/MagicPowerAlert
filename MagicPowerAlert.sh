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

# Gather the first 5 device names which report a 'BatteryPercent'
declare -a DEVICES
for findmagicitem in 1 2 3 4 5; do
    if name=$(/usr/sbin/ioreg -r -a -k BatteryPercent | /usr/bin/xmllint --xpath "
                /plist/
                array/
                    dict[$findmagicitem]/
                    key[.='Product']/
                        following-sibling::*[1]/
                        text()" - 2>/dev/null); then
            DEVICES+=("$name")
    fi
done

# Change nothing below here
messages=()

for index in ${!DEVICES[*]}; do
    device=${DEVICES[$index]}
    powerValue=$(/usr/sbin/ioreg -r -a -k BatteryPercent 2>&1 | /usr/bin/xmllint --xpath "
                    /plist/
                      array/
                        dict/
                          key[.='Product']/
                            following-sibling::*[1][text()=\"$device\"]/
                          ../
                            key[.='BatteryPercent']/
                              following-sibling::*[1]/
                                text()" - 2>/dev/null)
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
