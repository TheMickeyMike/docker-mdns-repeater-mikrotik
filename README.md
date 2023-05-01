# docker-mdns-repeater-mikrotik
An mDNS repeater that can run as a container on Mikrotik routers.

Based on:
* [geekman/mdns-repeater](https://github.com/geekman/mdns-repeater)
* [monstrenyatko/docker-mdns-repeater](https://github.com/monstrenyatko/docker-mdns-repeater)
* [TheMickeyMike/docker-mdns-repeater-mikrotik](https://github.com/TheMickeyMike/docker-mdns-repeater-mikrotik)

Images availabe on Dockerhub at [mag1024/mikrotik-docker-mdns-repeater](https://hub.docker.com/repository/docker/mag1024/mikrotik-docker-mdns-repeater).

## How it works
As of Oct 2022, the Mikrotik container implementation is limited to exactly one
network interface. There is no option for an equivalent of 'host' mode
networking, and the interface must be of type veth, so we have to get creative
to get a functional repeater. The key is to attach the veth to a trunk bridge
that contains multiple vlans corresponding to the networks we want to repeat
across, and then create interfaces for each of the vlans inside the container,
using the veth as the parent. The set of vlans/interfaces to use is specified
via the _REPEATER_INTERFACES_ env variable, and the container runs a dhcp client
to obtain an IP for each of them.

## Setup
Begin by following the [Mikrotik container
documentation](https://help.mikrotik.com/docs/display/ROS/Container) to create
the veth interface.  Instead of creating a separate docker bridge, assign the
new interface as a 'tagged' port to the bridge containing the interfaces you
wish to repeat across.  These interfaces can be vlan interfaces, or physical
interfaces with pvid set -- depending on whether you use vlans for the rest of
your network setup. Refer to the [Mikrotik bridge
documentation](https://help.mikrotik.com/docs/display/ROS/Bridge+VLAN+Table) for
more details.

The following example uses _veth-trunk_ veth interface and _br-trunk_ bridge,
configured with vlans 10, 11, 12.

Note: The address here does not matter, but it must have one to make the
interface 'active'.
```
/interface/veth/print
Flags: X - disabled; R - running
 0  R name="veth-trunk" address=10.200.200.200/24 gateway=10.200.200.1
```

Note: Again, pvid of the _veth_ itself does not matter.
```
/interface/bridge/port/print
Flags: I - INACTIVE; H - HW-OFFLOAD
Columns: INTERFACE, BRIDGE, HW, PVID, PRIORITY, PATH-COST, INTERNAL-PATH-COST, HORIZON
#    INTERFACE     BRIDGE    HW   PVID  PRIORITY  PATH-COST  INTERNAL-PATH-COST  HORIZON
0  H ether2        br-trunk  yes    10  0x80             10                  10  none
1  H ether3        br-trunk  yes    13  0x80             10                  10  none
...
8    veth-trunk    br-trunk        111  0x80             10                  10  none
```

Note: The name of the interface inside the container is always _eth0_.
```
/container/envs/print
 0 name="repeater_envs" key="REPEATER_INTERFACES" value="eth0.10 eth0.11 eth0.12"
```

Note: you may have to set the registry first via `/container/config/set registry-url=https://registry-1.docker.io`.
Note: `start-on-boot` is only available on Mikrotik 7.6+
```
/container/print
 0 ... tag="mag1024/mikrotik-docker-mdns-repeater:latest" os="linux"
   arch="arm64" interface=veth-trunk envlist="repeater_envs" mounts="" dns="" hostname="mdns-repeater" logging=yes
   start-on-boot=yes status=running
```
