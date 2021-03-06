#!/bin/sh

# /www/cgi-bin/config/config-sub.sh
# This script saves the settings when the Basic page is submitted

# Build the new script file
#---------------------------------------------------
cat > /tmp/conf-save.sh << EOF

#!/bin/sh

# Clear settings for **ALL** checkboxes and buttons
BUTTON="0"
LIMITIP="0"
ENSSL="0"


# Clear the dhcp test status message
rm /tmp/gatewaystatus.txt

# Get Field-Value pairs from QUERY_STRING enironment variable
# set by the form GET action
# Cut into individual strings: Field=Value

`echo $QUERY_STRING | cut -d \& -f 1`
`echo $QUERY_STRING | cut -d \& -f 2`
`echo $QUERY_STRING | cut -d \& -f 3`
`echo $QUERY_STRING | cut -d \& -f 4`
`echo $QUERY_STRING | cut -d \& -f 5`
`echo $QUERY_STRING | cut -d \& -f 6`
`echo $QUERY_STRING | cut -d \& -f 7`
`echo $QUERY_STRING | cut -d \& -f 8`
`echo $QUERY_STRING | cut -d \& -f 9`
`echo $QUERY_STRING | cut -d \& -f 10`
`echo $QUERY_STRING | cut -d \& -f 11`
`echo $QUERY_STRING | cut -d \& -f 12`
`echo $QUERY_STRING | cut -d \& -f 13`
`echo $QUERY_STRING | cut -d \& -f 14`
`echo $QUERY_STRING | cut -d \& -f 15`
`echo $QUERY_STRING | cut -d \& -f 16`
`echo $QUERY_STRING | cut -d \& -f 17`
`echo $QUERY_STRING | cut -d \& -f 18`
`echo $QUERY_STRING | cut -d \& -f 19`
`echo $QUERY_STRING | cut -d \& -f 20`
`echo $QUERY_STRING | cut -d \& -f 21`
`echo $QUERY_STRING | cut -d \& -f 22`
`echo $QUERY_STRING | cut -d \& -f 23`
`echo $QUERY_STRING | cut -d \& -f 24`
`echo $QUERY_STRING | cut -d \& -f 25`


# Refresh screen without saving 
if [ \$BUTTON = "Refresh" ]; then
	exit
fi

# Test for Gateway
if [ \$BUTTON = "Test" ]; then
	/bin/testgw.sh
	exit
fi

# Get logged in user
LOGINUSER=`cat /tmp/auth.txt`

# Change password, save the result, prepare status message, set web auth on.
rm /tmp/passwordstatus.txt
if [ \$BUTTON = "Set+Password" ]; then
	/bin/secn-setpassword.sh \$PASSWORD1 \$PASSWORD2 \$LOGINUSER
	exit
fi

# Set up the 'hash' character in Dialout prefix
if [ \$DIALOUT = "%23" ]; then
	DIALOUT="#"
fi

# Write TimeZone into /etc/TZ
echo \$TZ > /etc/TZ
uci set system.@system[0].timezone=\$TZ
uci commit system

# Write the Field values into the SECN config settings

# Write br_lan network settings into /etc/config/network
uci set network.lan.ipaddr=\$BR_IPADDR
uci set network.lan.gateway=\$BR_GATEWAY

# Write the Access Point wifi settings into /etc/config/secn
uci set secn.accesspoint.ssid=\$SSID
uci set secn.accesspoint.passphrase=\$PASSPHRASE
 
# Write the wireless channel into /etc/config/wireless
uci set wireless.radio0.channel=\$CHANNEL

# Save the web server settings
uci set secn.http.limitip=\$LIMITIP
uci set secn.http.enssl=\$ENSSL

# Commit the settings into /etc/config/ files
uci commit secn
uci commit network
uci commit wireless

# Create new config files
/etc/init.d/config_secn > /dev/null
/etc/init.d/config_secn-2 > /dev/null
# Make sure file writing is complete
sleep 2

# Save and Reboot
if [ \$BUTTON = "Reboot" ]; then
  # Output the reboot screen
  echo -en "Content-type: text/html\r\n\r\n"
  cat /www/cgi-bin/config/html/reboot.html
  touch /tmp/reboot			# Set rebooting flag
  /sbin/reboot -d 10		# Reboot after delay
fi

EOF
#-------------------------------------------------


# Make the file executable and run it to update the config settings
# Catch any error messages
chmod +x /tmp/conf-save.sh     > /dev/null
/tmp/conf-save.sh

# Check if rebooting
if [ -f /tmp/reboot ]; then
	exit
fi 

# Build the configuration screen and send it back to the browser.
/www/cgi-bin/secn-tabs

# Clean up temporary files
rm /tmp/conf-save.sh           > /dev/null
rm /tmp/config.html            > /dev/null

