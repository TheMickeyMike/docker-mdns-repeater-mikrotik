#!/bin/bash

# Exit on error
set -e

HOSTNAME="mDns"
INTERFACE="eth0"
VLANS="20 100"

MTU=$(ip link show "$INTERFACE" | awk '{print $5}')

for VLAN in $VLANS; do
    # INTERFACE PROVISION
    IFNAME="${INTERFACE}.${VLAN}"
    [ ! -d "/sys/class/net/${IFNAME}" ] && {
        echo "create interface ${IFNAME}"
        ip link add link "$INTERFACE" name "$IFNAME" mtu "$MTU" type vlan id "$VLAN"
    }
    echo "bring up ${IFNAME} interface"
    ip link set "${IFNAME}" up

    # DHCP
    [ -f "/var/run/udhcpc.${IFNAME}.pid" ] && {
        kill "$(cat "/var/run/udhcpc.$IFNAME.pid")" || true
        rm "/var/run/udhcpc.$IFNAME.pid"
    }
    echo "starting dhcp client on ${IFNAME}"
    udhcpc -b -i "$IFNAME" -x hostname:"$HOSTNAME" -p "/var/run/udhcpc.${IFNAME}.pid"
done

exec "$@"
