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



----------------------- VXLAN -----------------------

L2 frame (host1)
   ↓
VXLAN encapsulation (UDP)
   ↓
IP routing (R1 → R2)
   ↓
decapsulation
   ↓
L2 frame (host2)

----------------- on R1 ---------------
<!-- Create VXLAN interface on -->

ip link add vxlan0 type vxlan id 10 dev eth1 remote 1.0.0.6 dstport 4789

<!-- create bridge -->

ip link add br0 type bridge

<!-- Add interfaces to bridge -->

ip link set eth0 master br0
ip link set vxlan0 master br0

<!-- Bring everything up -->
ip link set eth0 up
ip link set vxlan0 up
ip link set br0 up



----------------- on R2 ---------------
<!-- Create VXLAN interface on -->

ip link add vxlan0 type vxlan id 10 dev eth1 remote 1.0.0.5 dstport 4789

<!-- create bridge -->

ip link add br0 type bridge

<!-- Add interfaces to bridge -->

ip link set eth0 master br0
ip link set vxlan0 master br0

<!-- Bring everything up -->
ip link set eth0 up
ip link set vxlan0 up
ip link set br0 up


------------------- host1 ------------------

ip addr add 192.168.1.1/24 dev eth0
ip link set eth0 up

------------------- host2 ------------------

ip addr add 192.168.1.2/24 dev eth0
ip link set eth0 up



--------------------------switch-------------------------

<!-- Install bridge support -->
ip link add br0 type bridge

<!-- Attach interfaces -->
ip link set eth0 master br0
ip link set eth1 master br0

<!-- Bring everything up -->

ip link set eth0 up
ip link set eth1 up
ip link set br0 up



------------------------- check that we are using vxlan -------------------------

<!-- Break VXLAN intentionally and ping  -->

ip link set vxlan0 down