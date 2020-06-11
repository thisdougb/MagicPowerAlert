#!/usr/bin/env bash
#
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
        messages[$index]="$device at $powerValue%$status"
    fi
done

len=${#messages[@]}
if (( "$len" > 0 )); then
    for index in ${!messages[*]}; do
        echo "${messages[$index]}"
    done
fi
