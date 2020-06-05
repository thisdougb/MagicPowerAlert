#!/usr/bin/env bash
#
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
    statusFlag=$(/usr/sbin/ioreg -r -a -k BatteryPercent 2>&1 | /usr/bin/xmllint --xpath "
                    /plist/
                      array/
                        dict/
                          key[.='Product']/
                            following-sibling::*[1][text()=\"$device\"]/
                          ../
                            key[.='BatteryStatusFlags']/
                              following-sibling::*[1]/
                                text()" - 2>/dev/null)
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
