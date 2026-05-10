# Post-boot setup

The FRR daemons (OSPF, BGP, EVPN) start automatically from the config files.
Run the steps below once the containers are up.

---

## 1. R2, R3, R4 — Linux VXLAN bridge

FRR handles the BGP/EVPN side, but the VXLAN and bridge interfaces must be
created at the Linux level. Run on each leaf, changing the two variables:

| Leaf | LOCAL_LO | HOST_IF |
|------|----------|---------|
| R2   | 10.0.0.2 | eth1    |
| R3   | 10.0.0.3 | eth0    |
| R4   | 10.0.0.4 | eth0    |

```bash
LOCAL_LO=10.0.0.4
HOST_IF=eth0

# VXLAN tunnel — source is loopback, nolearning lets EVPN control the FDB
ip link add vxlan10 type vxlan id 10 dstport 4789 local $LOCAL_LO nolearning

# Bridge joining the VXLAN tunnel and the host-facing port
ip link add br10 type bridge
ip link set vxlan10 master br10
ip link set $HOST_IF master br10

ip link set vxlan10 up
ip link set br10 up
ip link set $HOST_IF up
```

---

## 2. Hosts — IP configuration

```bash
# host_iantar-1
ip addr add 20.1.1.1/24 dev eth1 && ip link set eth1 up

# host_iantar-2
ip addr add 20.1.1.2/24 dev eth0 && ip link set eth0 up

# host_iantar-3
ip addr add 20.1.1.3/24 dev eth0 && ip link set eth0 up
```

---

## 3. Verification

```bash
# On any leaf — one EVPN neighbor (the RR), should be Established
vtysh -c "show bgp l2vpn evpn summary"

# Before host traffic — only type-3 routes (one per VTEP)
vtysh -c "show bgp l2vpn evpn"

# After a host sends a packet — type-2 routes (MAC) appear automatically
vtysh -c "show bgp l2vpn evpn"

# VNIs FRR has detected locally
vtysh -c "show evpn vni"

# MACs known for VNI 10
vtysh -c "show evpn mac vni 10"

# Cross-leaf ping (from host_iantar-1)
ping 20.1.1.2

# Confirm VXLAN encapsulation on the wire
tcpdump -i eth0 -n udp port 4789
```
