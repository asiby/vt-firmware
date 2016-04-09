#!/bin/sh -x
# /bin/config_secn_wan.sh

#Set up WAN Port

# Get WAN settings
WANPORT=`uci get secn.wan.wanport`
WANLAN_ENABLE=`uci get secn.wan.wanlan_enable`
ETHWANMODE=`uci get secn.wan.ethwanmode`
WANIP=`uci get secn.wan.wanip`
WANGATEWAY=`uci get secn.wan.wangateway`
WANMASK=`uci get secn.wan.wanmask`
WANDNS=`uci get secn.wan.wandns`
PORT_FORWARD=`uci get secn.wan.port_forward`
SECWANIP=`uci get secn.wan.secwanip`

WANSSID=`uci get secn.wan.wanssid`
WANSSID=`echo "$WANSSID" | sed -f /bin/url-decode.sed`
uci set secn.wan.wanssid=$WANSSID

WANPASS=`uci get secn.wan.wanpass`
WANPASS=`echo "$WANPASS" | sed -f /bin/url-decode.sed`
uci set secn.wan.wanpass=$WANPASS

# Get Mesh setting
MESH_DISABLE=`uci get secn.mesh.mesh_disable`

# Set up connection tracking max
CONNTRACK_MAX=`uci get secn.wan.conntrack_max`
sysctl -w net.netfilter.nf_conntrack_max=$CONNTRACK_MAX

# Set up WAN Port Forwarding for ssh and https
	uci set firewall.https.dest="NULL"
	uci set firewall.ssh.dest="NULL"
if [ $PORT_FORWARD = "checked" ]; then                                   
	uci set firewall.https.dest="lan"
	uci set firewall.ssh.dest="lan"
fi

# Set up WAN wifi encryption 
WANENCRYPTION=`uci get secn.wan.wanencr`
# Set to WPA by default                                 
WANENCR="psk"

if [ $WANENCRYPTION = "WPA-WPA2-AES" ]; then                                   
	WANENCR="mixed-psk+tkip+aes"
elif [ $WANENCRYPTION = "WPA-WPA2" ]; then                          
	WANENCR="mixed-psk"
elif [ $WANENCRYPTION = "WPA2" ]; then                          
	WANENCR="psk2"
elif [ $WANENCRYPTION = "WPA" ]; then                                   
	WANENCR="psk"
elif [ $WANENCRYPTION = "WEP" ]; then                          
	WANENCR="wep"                                                     
elif [ $WANENCRYPTION = "NONE" ]; then                          
	WANENCR="none"                                                      
fi

# Set WAN wifi config
uci set wireless.sta_0.ssid=$WANSSID
uci set wireless.sta_0.key=$WANPASS
uci set wireless.sta_0.encryption=$WANENCR

# Clear WAN settings
uci set network.wan.ifname=''
uci set network.wan.proto=''
uci set network.wan.type=''
uci set network.wan.ipaddr=''
uci set network.wan.gateway=''
uci set network.wan.netmask=''
uci set network.wan.dns=''

uci set network.wan.service=''
uci set network.wan.apn=''
uci set network.wan.username=''
uci set network.wan.password=''
uci set network.wan.pin=''
uci set network.wan.device=''
uci set wireless.sta_0.disabled='1' # Make sure wifi WAN is off.
uci set network.stabridge.network='wwan' # Disable wifi relay bridge
/etc/init.d/relayd disable # Disable relayd

# Check to see if eth1 port exists eg for NanoStation M
if [ `ls /proc/sys/net/ipv4/conf | grep eth1` ]; then
	ETH1_PRESENT='1'
	else
	ETH1_PRESENT='0'
	# Clear WAN port bridging
	uci set secn.wan.wanlan_enable='0'
	WANLAN_ENABLE='0'
fi

# Set up for WAN port bridged to LAN
if [ $WANLAN_ENABLE = "checked" ]; then
	uci set network.lan.ifname='eth0 eth1'
else
	uci set network.lan.ifname='eth0'
fi

# Set up for WAN disabled
if [ $WANPORT = "Disable" ]; then
  # Nothing to do
	true
fi

# Set up for Ethernet WAN
if [ $WANPORT = "Ethernet" ]; then
    uci set network.lan.gateway='255.255.255.255'
	# Clear WAN port bridging
	uci set secn.wan.wanlan_enable='0'
	# Set up for WAN port on eth 0 or eth1
	if [ $ETH1_PRESENT = '1' ]; then
		uci set network.lan.ifname='eth0'  # make eth0 LAN
		uci set network.wan.ifname='eth1'  # make eth1 WAN
	else
		uci set network.lan.ifname='eth9'  # dummy LAN
		uci set network.wan.ifname='eth0'  # make etho WAN
	fi
	# Disable WAN port as LAN
	uci set secn.wan.wanlan_enable='0'
fi

# Set up for Mesh WAN
if [ $WANPORT = "Mesh" ]; then
 	# Set up eth1 as LAN or WAN
	if [ $ETH1_PRESENT = '1' ]; then
		if [ $WANLAN_ENABLE = "checked" ]; then
			uci set network.wan.ifname='bat0'
			uci set network.lan.ifname='eth0 eth1'
		else 
			uci set network.wan.ifname='bat0 eth1' 
			uci set network.lan.ifname='eth0'
		fi
	else 
		uci set network.wan.ifname='bat0'
		uci set network.lan.ifname='eth0'
	fi
	uci set network.lan.gateway='255.255.255.255'
	uci set network.wan.type='bridge' # Reqd. See /etc/init.d/set-mesh-gw-mode
	MESH_DISABLE='0'
	uci set secn.mesh.mesh_disable='0'
fi

# Disable mesh if required
if [ $MESH_DISABLE = "0" ]; then
  uci set wireless.ah_0.disabled='0'
else
	uci set wireless.ah_0.disabled='1'
fi

# Set up for WiFi WAN
if [ $WANPORT = "WiFi" ]; then
	uci set network.lan.gateway='255.255.255.255'
	uci set wireless.sta_0.disabled='0'
	uci set wireless.sta_0.network='wan'
	uci set wireless.ah_0.disabled='1'
	uci set secn.mesh.mesh_disable='1'
	uci set network.wan.ifname='wlan0-2'
fi

# Set up for WiFi Relay WAN
if [ $WANPORT = "WiFi-Relay" ]; then
	uci set network.stabridge.network='lan wwan'
	uci set wireless.sta_0.network='wwan'
	uci set wireless.sta_0.disabled='0'
	uci set wireless.ah_0.disabled='1'
	uci set secn.mesh.mesh_disable='1'
	/etc/init.d/relayd enable
fi

# Set up for DHCP or Static
if [ $ETHWANMODE = "Static" ]; then
	uci set network.wan.proto='static'
	uci set network.wan.ipaddr=$WANIP
	uci set network.wan.gateway=$WANGATEWAY
	uci set network.wan.netmask=$WANMASK
	uci set network.wan.dns=$WANDNS

else  # Set up for DHCP
	uci set network.wan.proto='dhcp'
	uci set network.wan.ipaddr=''
	uci set network.wan.gateway=''
	uci set network.wan.netmask=''
	uci set network.wan.dns=''
fi


# Make sure firewall is enabled
/etc/init.d/firewall enable  


