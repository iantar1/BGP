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




# evpn

This is Linux-level configuration, not FRR. FRR's role is just to advertise what the kernel already has. So on each leaf you'll run something like:

```bash 
ip link add vxlan10 type vxlan id 10 dstport 4789 local 10.0.0.2 nolearning
ip link add br10 type bridge
ip link set vxlan10 master br10
ip link set <host-facing-eth> master br10
ip link set vxlan10 up
ip link set br10 up 
```

(Replace 10.0.0.2 with the leaf's own loopback, and <host-facing-eth> with the interface connected to its host.)


3. advertise-all-vni is missing on the leaves
Even with the VXLAN interface up and the EVPN address family activated, FRR won't advertise local VNIs unless you explicitly tell it to. Add this to R2, R3, R4:
```bash
 address-family l2vpn evpn
  neighbor 10.0.0.1 activate
  advertise-all-vni
 exit-address-family
 ```