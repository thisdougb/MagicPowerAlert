# MagicPowerAlert
Convenient low-battery notification for your Apple Mac with Bluetooth devices.

Mac OS warns your Magic Mouse is running out of power at 2%. Not ideal given the charging port location.
MagicPowerAlert lets you know at 20%, giving you lots of time to fit in a charging session at a time of your choosing.

Competency level: comfortable using Terminal, and cron.

### Screencast
I put up a [screencast](https://vimeo.com/413113839) running through how to install.

### Instructions:

##### Download Code

```
$ mkdir MagicPower
$ cd MagicPower
$ curl -L0 -O https://raw.githubusercontent.com/thisdougb/MagicPowerAlert/master/MagicPowerAlert.sh
```
##### Configure
The default should be fine, it'll pick up either mouse or keyboard below 20% power.
But you can change this is you like.

```
$ head MagicPowerAlert.sh
#!/usr/bin/env bash

# You can change the default threshold of 20% by supplying an argument to the script
THRESHOLD=20

# You can change the message here, if coffee is not your thing
MESSAGE="Get a coffee and charge:\n"
```

#### Test
Give it a quick test, set the alert THRESHOLD to 100 by supplying as an argument.
A window prompt should pop-up, with your alert.
```
$ chmod +x MagicPowerAlert.sh
$ ./MagicPowerAlert 100
```

#### View Battery and Charging Status (without the popup alert)
```
$ ./MagicPowerAlert.sh status
Magic Keyboard with Numeric Keypad at 98%
Magic Mouse 2 at 47% (charging)
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

 A field may be an asterisk (*), which always stands for ``first-last''.

 Ranges of numbers are allowed.  Ranges are two numbers separated with a hyphen.  The specified range is inclu-
 sive.  For example, 8-11 for an ``hours'' entry specifies execution at hours 8, 9, 10 and 11.

 Lists are allowed.  A list is a set of numbers (or ranges) separated by commas.  Examples: ``1,2,5,9'',
 ``0-4,8-12''.
```
Add an entry similar to this, but with your path and time preferences.
This runs every morning at 09:30:
```
30 9 * * * /Users/dougb/dev/scripts/MagicPowerAlert.sh
```
#### Switch Off
Of course you can delete the cron entry, or simply comment it out.
```
# switched off
#30 9 * * * /Users/dougb/dev/scripts/MagicPowerAlert.sh
```

