# MagicPowerAlert
Convenient low-battery notification for your Apple Mac with Bluetooth devices.

<p align="center">
  <img src="https://github.com/thisdougb/thisdougb.github.io/blob/master/images/MagicPowerAlert.png" />
</p>

Mac OS warns your Magic Mouse is running out of power at 2%. Not ideal given the charging port location.
MagicPowerAlert lets you know at 20%, giving you lots of time to fit in a charging session at a time of your choosing.

Competency level: comfortable using Terminal, and cron.

### Instructions:

##### Download Code

```
$ mkdir MagicPower
$ cd MagicPower
$ curl -L0 -O https://raw.githubusercontent.com/thisdougb/MagicPowerAlert/master/MagicPowerAlert.sh
```
#### View Battery and Charging Status (without the pop-up alert)
```
$ ./MagicPowerAlert.sh status
Magic Keyboard with Numeric Keypad at 98%
Magic Mouse 2 at 47% (charging)
```
#### Configure
The default should be fine, it'll pick up either mouse or keyboard below 20% power.
But you can change this is you like.

```
# Set to mute consecutive alerts for a period of minutes. Makes it practical to schedule
# MagicPowerAlert to run frequently, say every 30 minutes. Really, two alerts per day are
# probably enough of a reminder. So a good value is maybe 4 hours.
MUTE_CONSECUTIVE_ALERTS_HOURS=4

# Inactivity detection. If user is afk, don't continue and possibly spam the desktop with alerts.
# For example, no alerts during the night when running other automated tasks.
INACTIVITY_THRESHOLD_MINS=5

# You can change the message, if coffee is not your thing.
MESSAGE="Get a coffee and charge:\n"
```
#### Test Pop-up Alert
Give it a quick test, set the alert THRESHOLD to 100 by supplying as an argument.
A window prompt should pop-up, with your alert.
```
$ chmod +x MagicPowerAlert.sh
$ ./MagicPowerAlert.sh 100
```
Remember that running while muted will not pop-up an alert. So just remove this file if you want to re-test.
```
$ ls -l MagicPowerAlert.sh.mute
-rw-r--r--  1 dougb  staff  0  4 Apr 11:29 MagicPowerAlert.sh.mute
```
#### Schedule It
If you haven't used cron before, then the relevant info (from 'man 5 cron') is:
```
The time and date fields are:

       field         allowed values
       -----         --------------
       minute        0-59
       hour          0-23
       day of month  1-31
       month         1-12 (or names, see below)
       day of week   0-7 (0 or 7 is Sun, or use names)

A field may be an asterisk (*), which always stands for first-last.

To specific a range use 9-12, which gives 9, 10, 11, 12.

To step through a range use */<step>, for example */5 will give 0, 5, 10, etc.
```
Add a cron entry with your file path and time preferences.
To avoid waking up to a hundred pop-up alerts, ensure you configure muting and inactivity to suitable values.

For example, this runs every 30 minutes:
```
*/30 * * * * /Users/dougb/dev/MagicPowerAlert/MagicPowerAlert.sh
```
#### Switch Off
Of course you can delete the cron entry, or simply comment it out.
```
# switched off
#*/30 * * * * /Users/dougb/dev/MagicPowerAlert/MagicPowerAlert.sh
```
