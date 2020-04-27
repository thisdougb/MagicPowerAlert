#!/usr/bin/env bash
#
# 1. Save locally, chmod +x <file>
#
# 2. Add a cron entry to run it, for example:
#   30 9 * * * /Users/dougb/dev/scripts/MagicMousePower.sh
#
# (OSX asks permission to run this the first time)
#

# You can change the threshold
THRESHOLD=20

# You can change the message, if coffee is not your thing
MESSAGE="Get a coffee and charge:\n"

# Probably best leave this as is
DEVICES=("Magic Mouse 2" "Magic Keyboard")

# Change nothing below here
messages=()

for index in ${!DEVICES[*]}
do
        device=${DEVICES[$index]}
                                                                                     # trying to make it readable
        powerValue=$(/usr/sbin/ioreg -r -l -n AppleHSBluetoothDevice -a              \
                | awk -v dev="$device"                                               \
                        'BEGIN { battery_value = 0 }                                 \
                         /\<key\>BatteryPercent\<\/key\>/                            \
                                {                                                    \
                                        getline;                                     \
                                        match($0, "[0-9]{1,3}");                     \
                                        battery_value = substr($0, RSTART, RLENGTH)  \
                                 }                                                   \
                         /\<key\>Product\<\/key\>/                                   \
                                {                                                    \
                                        getline;                                     \
                                        if ($0 ~ dev) {                              \
                                                print battery_value;                 \
                                                exit 0;                              \
                                        } else {                                     \
                                                battery_value = 0                    \
                                        }                                            \
                                }                                                    \
                         ')

	int_re='^[0-9]+$'
	if [[ $powerValue =~ $int_re ]] ; then
        	if [ $powerValue -le $THRESHOLD ]; then
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

        for index in ${!messages[*]}
        do
                message="$message\n\t${messages[$index]}"
        done

        /usr/bin/osascript <<-EOF
           tell application "System Events"
              activate
             display dialog "$message"
           end tell
	EOF
fi
