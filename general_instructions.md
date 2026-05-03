<!-- assign an ip to a device interface -->
ip addr add 10.0.0.1/30 dev eth0

<!-- activating the network interface -->
ip link set eth0 up


<!-- add route  -->

ip route add (network ip to be reached ) via (next reachable device ip)
ip route add 10.0.0.4/30 via 10.0.0.2




give the three hosts ips in  the smae subnet
<!--

    host1 --- eth0 [host2] eth1 --- host3
            \      |
            \---- br0 (virtual switch)

-->

<!-- kernel routing table -->
ip route list

<!-- make a host act like a switch -->
ip link add br0 type bridge

<!-- eth0 is plugged into the switch (br0) -->
ip link set eth0 master br0

<!-- eth1 is plugged into the same switch (br0) -->
ip link set eth1 master br0

ip link set br0 up
ip link set eth0 up
ip link set eth1 up


<!-- Show MAC table -->
bridge fdb show




<!-- zebra → talks to Linux kernel (adds routes you see in ip route) -->
<!-- ripd → learns/sends RIP routes -->
<!-- watchfrr → supervises everything (like a process manager) -->

<!--

ripd → learns routes
   ↓
zebra → installs them into kernel
   ↓
Linux kernel → forwards packets 

-->


<!-- add a default gateway -->
ip route add default via 10.0.0.5


