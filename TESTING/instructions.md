<!-- add ips abd default gateway for host1 and host2 -->
<!-- host1 -->
ip addr add 1.0.0.1/30 dev eth0
ip route add default via 1.0.0.2

<!-- host2 -->
ip addr add 1.0.0.10/30 dev eth0
ip route add default via 1.0.0.9


<!-- configure the switch -->

ip link add br0 type bridge
ip link set eth0 master br0
ip link set eth1 master br0
ip link set br0 up
ip link set eth0 up
ip link set eth1 up