# docker-mdns-repeater-mikrotik
mdns-repeater in mikrotik container

Based on:
https://github.com/geekman/mdns-repeater
https://github.com/monstrenyatko/docker-mdns-repeater

This is work in progress, but you can base your config on that.

## Mikrotik config
Based on official docs https://help.mikrotik.com/docs/display/ROS/Container
Instead of adding `veth2` to docker bridge i've added it to my home-lan bridge `BR1`.
Veth2 is added as tagged port with two vlans (20,100), so in container on `eth0` i will create two vlan interfaces `eth0.20` and `eth0.100` with active dhcp client for IP leese, please look at `run.sh`.

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
```
docker buildx build --no-cache --platform linux/arm/v6 -t mdns .
docker save mdns > mdns.tar
8.8M mdns.tar # size after pack
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