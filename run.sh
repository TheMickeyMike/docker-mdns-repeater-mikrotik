#!/bin/bash

# Exit on error
set -e

MTU=$(ip link show "${REPEATER_INTERFACES%%[ .]*}" | awk '{print $5}')

for IFNAME in $REPEATER_INTERFACES; do
    # INTERFACE PROVISION
    [ ! -d "/sys/class/net/$IFNAME" ] && {
        echo "create interface $IFNAME"
        ip link add link "${IFNAME%%.*}" \
             name "$IFNAME" mtu "$MTU" type vlan id "${IFNAME##*.}"
    }
    echo "bring up $IFNAME interface"
    ip link set "$IFNAME" up

    # DHCP
    [ -f "/var/run/udhcpc.$IFNAME.pid" ] && {
        kill "$(cat "/var/run/udhcpc.$IFNAME.pid")" || true
        rm "/var/run/udhcpc.$IFNAME.pid"
    }
    echo "starting dhcp client on $IFNAME"
    udhcpc -b -i "$IFNAME" -x hostname:"$(hostname)" -p "/var/run/udhcpc.$IFNAME.pid"
done

exec /bin/mdns-repeater -f $REPEATER_INTERFACES
