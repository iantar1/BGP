# host 1
<!-- assign ip and default gateway -->
ip addr add 1.0.0.14/30 dev eth1
ip route add default via 1.0.0.13

# host 2
<!-- assign ip and default gateway -->
ip addr add 1.0.0.18/30 dev eth0
ip route add default via 1.0.0.17

<!-- assign ip and default gateway -->
# host 3
ip addr add 1.0.0.22/30 dev eth0
ip route add default via 1.0.0.21


