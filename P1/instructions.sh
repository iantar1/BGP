# “No IP address should be configured by default”

ip addr add 10.0.0.1/24 dev eth0
ip link set eth0 up

ip addr add 10.0.0.2/24 dev eth0
ip link set eth0 up