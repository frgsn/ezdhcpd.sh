#!/bin/bash


while [[ "$1" ]]; do
  case $1 in
    '-i')
      IFACE="$2"
      shift
      ;;

    'clean')
      do_clean=1
      ;;

    *)
      printf 'ERROR: invalid CLI argument "%s"' $1
      exit 1
      ;;
  esac
  shift
done


# TODO - make script smart enough to automatically pick a network
# prefix/subnet mask if the defaults are already in use on the system
IP_START_RANGE=${IP_START_RANGE-'192.168.10.2'}
IP_END_RANGE=${IP_END_RANGE-'192.168.10.254'}
# TODO - make the script smart enough to automatically populate the CIDR
# notation from the mask and vice-versa. Right now changing the subnet mask
# requires manually keeping both of these variables in sync
SUBNET_MASK=${SUBNET_MASK-'255.255.255.0'}
SUBNET_MASK_CIDR=${SUBNET_MASK_CIDR-'24'}
IFACE=${IFACE-'eth0'}
SERVER_IP=${SERVER_IP-'192.168.10.1'}


if [[ $UID != 0 ]]; then
  echo 'ERROR: This script must be run as root.'
  exit 1
fi


# check to make sure the given interface exists
ip link | grep $IFACE >/dev/null
if [[ $? != 0 ]]; then
  printf 'ERROR: the given interface "%s" does not appear to exist.' $IFACE
  exit 1
fi


# convenience CLI option to tear down the interface
if [[ "$do_clean" ]]; then
  ip link set down $IFACE
  ip addr del dev $IFACE local $SERVER_IP/$SUBNET_MASK_CIDR
  exit
fi


# check to make sure busybox/udhcpd is installed
busybox udhcpd --help >/dev/null 2>/dev/null
if [[ $? != 0 ]]; then
  echo "ERROR: udhcpd doesn't appear to be installed."
  exit 1
fi


# set up the interface
#
# we have to do this here since udhcpd does not do it for us (even though we
# have to specify the local address on the command line). The DHCP server will
# still work and the remote device will get an IP address, it just won't have a
# a way to talk back to the local machine.

ip addr add dev $IFACE local $SERVER_IP/$SUBNET_MASK_CIDR
ip link set up dev $IFACE


# start the DHCP server
busybox udhcpd -f -I $SERVER_IP /dev/stdin <<EOF

################################################################################
# BEGIN UDHCPD.CONF
################################################################################

# This section of the file acts as an embedded conf file for udhcpd.
# Options specified here will have the same effect as options specified at
# /etc/udhcpd.conf

start         $IP_START_RANGE
end           $IP_END_RANGE
interface     $IFACE
option subnet $SUBNET_MASK

################################################################################
# END UDHCPD.CONF
################################################################################

EOF


exit $?
