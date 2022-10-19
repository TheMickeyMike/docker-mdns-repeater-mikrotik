# docker-mdns-repeater-mikrotik
mdns-repeater in mikrotik container

Based on:
* [geekman/mdns-repeater](https://github.com/geekman/mdns-repeater)
* [monstrenyatko/docker-mdns-repeater](https://github.com/monstrenyatko/docker-mdns-repeater)

## How it works
As of Oct 2022, the Mikrotik container implementation is limited to exactly one
network interface. There is no option for an equivalent of 'host' mode
networking, and the interface must be of type veth, so we have to get creative
to get a functional repeater. The key is to attach the venth to a trunk bridge
that contains multiple vlans corresponding to the networks we want to repeat
across, and then create interfaces for each of the vlans inside the container,
using the veth as the parent. The set of vlans/interfaces to use is specified
via the _REPEATER_INTERFACES_ env variable, and the container runs a dhcp client
to obtain an IP for each of them.

## Setup
Begin by following the [Mikrotik container
documentation](https://help.mikrotik.com/docs/display/ROS/Container) to create
the veth interface. Make sure you assign it an address -- what it
is doesn't matter, but it is necessary make the interface 'active'.
Instead of creating a separate docker bridge, assign the new interface as a
'tagged' port to the bridge containing the interfaces you wish to repeat across.
These interfaces can be vlan interfaces, or physical interfaces with pvid set --
depending on whether you use vlans for the rest of your network setup. Refer to
the [Mikrotik bridge
documentation](https://help.mikrotik.com/docs/display/ROS/Bridge+VLAN+Table) for
more details.

The following example uses _veth2_ veth interface and _BR1_ home lan bridge,
configured with vlans 20 and 100.

```
 /interface/bridge/port/print 
Flags: I - INACTIVE; H - HW-OFFLOAD
Columns: INTERFACE, BRIDGE, HW, PVID, PRIORITY, PATH-COST, INTERNAL-PATH-COST, HOR
IZON
 #    INTERFACE  BRIDGE  HW   PVID  PRIORITY  PATH-COST  IN  HORIZON
10    veth2      BR1             1  0x80             10  10  none


/interface/bridge/vlan/print
Flags: D - DYNAMIC
Columns: BRIDGE, VLAN-IDS, CURRENT-TAGGED, CURRENT-UNTAGGED
#   BRIDGE  VLAN-IDS  CURRENT-TAGGED  CURRENT-UNTAGGED
0   BR1          100  BR1                                                  
                      veth2                           
3   BR1           20  BR1                                                 
                      veth2                                                    
4 D BR1            1                  BR1                   
                                      veth2 
```

## Build & pack container
Before you begin, make sure your docker instance is set up for cross-compilation, e.g by running
```
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
```

Use platform for your router, e.g. _linux/arm/v6_, _linux/arm/v7_, or
_linux/arm64_.

```
docker buildx build --network host --no-cache --platform linux/arm64 -t mdns-repeater .
docker save mdns-repeater -o mdns-repeater.tar
```

## Deploy the container
Upload the mdns-repeater.tar file to the router.
The name of the interface inside the container is always _eth0_.
If the version of your RouterOS is at least 7.6, you can add _start-on-boot=yes_
to the container parameters.

```
/container/envs/add name=repeater_envs key=REPEATER_INTERFACES value="eth0.20 eth0.100"
/container/add file=mdns-repeater.tar interface=veth2 envlist=repeater_envs hostname=mdns-repeater logging=yes
/container/print  # wait for the container to be done extracting
/container/start 0
```

## Logs from running container
```
log print where topics~"container"
 jun/29 22:01:28 container,info,debug create interface eth0.20
 jun/29 22:01:28 container,info,debug bring up eth0.20 interface
 jun/29 22:01:28 container,info,debug /app/run.sh: line 25: kill: (19) - No such process
 jun/29 22:01:28 container,info,debug starting dhcp client on eth0.20
 jun/29 22:01:28 container,info,debug udhcpc: started, v1.35.0
 jun/29 22:01:29 container,info,debug udhcpc: broadcasting discover
 jun/29 22:01:29 container,info,debug udhcpc: broadcasting select for 10.0.20.27, server 10.0.20.1
 jun/29 22:01:29 container,info,debug udhcpc: lease of 10.0.20.27 obtained from 10.0.20.1, lease time 86400
 jun/29 22:01:29 container,info,debug create interface eth0.100
 jun/29 22:01:29 container,info,debug bring up eth0.100 interface
 jun/29 22:01:29 container,info,debug /app/run.sh: line 25: kill: (34) - No such process
 jun/29 22:01:29 container,info,debug starting dhcp client on eth0.100
 jun/29 22:01:29 container,info,debug udhcpc: started, v1.35.0
 jun/29 22:01:29 container,info,debug udhcpc: broadcasting discover
 jun/29 22:01:30 container,info,debug udhcpc: broadcasting select for 10.0.100.244, server 10.0.100.1
 jun/29 22:01:30 container,info,debug udhcpc: lease of 10.0.100.244 obtained from 10.0.100.1, lease time 86400
 jun/29 22:01:30 container,info,debug + exec /bin/mdns-repeater -f eth0.20 eth0.100
 jun/29 22:01:30 container,info,debug mdns-repeater: dev eth0.20 addr 10.0.20.27 mask 255.255.255.0 net 10.0.20.0
 jun/29 22:01:30 container,info,debug mdns-repeater: dev eth0.100 addr 10.0.100.244 mask 255.255.255.0 net 10.0.100.0
 jul/01 21:49:34 container,info,debug bring up eth0.20 interface
 jul/01 21:49:34 container,info,debug /app/run.sh: line 25: kill: (22) - No such process
 jul/01 21:49:34 container,info,debug starting dhcp client on eth0.20
 jul/01 21:49:34 container,info,debug udhcpc: started, v1.35.0
 jul/01 21:49:34 container,info,debug udhcpc: broadcasting discover
 jul/01 21:49:34 container,info,debug udhcpc: broadcasting select for 10.0.20.27, server 10.0.20.1
 jul/01 21:49:34 container,info,debug udhcpc: lease of 10.0.20.27 obtained from 10.0.20.1, lease time 86400
 jul/01 21:49:34 container,info,debug bring up eth0.100 interface
 jul/01 21:49:34 container,info,debug /app/run.sh: line 25: kill: (40) - No such process
 jul/01 21:49:34 container,info,debug starting dhcp client on eth0.100
 jul/01 21:49:34 container,info,debug udhcpc: started, v1.35.0
 jul/01 21:49:34 container,info,debug udhcpc: broadcasting discover
 jul/01 21:49:35 container,info,debug udhcpc: broadcasting select for 10.0.100.244, server 10.0.100.1
 jul/01 21:49:35 container,info,debug udhcpc: lease of 10.0.100.244 obtained from 10.0.100.1, lease time 86400
 jul/01 21:49:35 container,info,debug + exec /bin/mdns-repeater -f eth0.20 eth0.100
 jul/01 21:49:35 container,info,debug mdns-repeater: dev eth0.20 addr 10.0.20.27 mask 255.255.255.0 net 10.0.20.0
 jul/01 21:49:35 container,info,debug mdns-repeater: dev eth0.100 addr 10.0.100.244 mask 255.255.255.0 net 10.0.100.0
```
