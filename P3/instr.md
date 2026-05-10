# EVPN Setup

commands needed to enable BGP EVPN with VXLAN VNI 10.

---

## 1. R1 (Route Reflector) — FRR commands

Enter vtysh and add the EVPN address family. RR-client must be set **inside** the EVPN family — the global one does not carry over.

```bash
# Open FRR's CLI
vtysh

# Enter config mode
configure terminal

# Go into the existing BGP process
router bgp 65000

# Enter the EVPN address family
address-family l2vpn evpn

# Activate EVPN exchange with each leaf neighbor
neighbor 10.0.0.2 activate
neighbor 10.0.0.3 activate
neighbor 10.0.0.4 activate

# Reflect EVPN routes between leaves (must be set HERE, not just globally)
neighbor 10.0.0.2 route-reflector-client
neighbor 10.0.0.3 route-reflector-client
neighbor 10.0.0.4 route-reflector-client

# Exit address family + config, then save
exit-address-family
end
write memory
```

---

## 2. R2, R3, R4 (Leaves) — FRR commands

Same block on each leaf. The only line that differs per leaf is the BGP router ID, which is already in your config.

```bash
vtysh
configure terminal

# Go into the existing BGP process
router bgp 65000

# Enter the EVPN address family
address-family l2vpn evpn

# Activate EVPN exchange with the RR
neighbor 10.0.0.1 activate

# Auto-advertise every locally-configured VNI
# This is what triggers generation of type 3 (VTEP presence)
# and type 2 (MAC) routes
advertise-all-vni

exit-address-family
end
write memory
```

---

## 3. R2, R3, R4 (Leaves) — Linux VXLAN bridge

FRR cannot create the VXLAN interface itself. Run these on each leaf, **changing two values per device**:

| Leaf | LOCAL_LO | HOST_IF |
|------|----------|---------|
| R2 | 10.0.0.2 | eth1 |
| R3 | 10.0.0.3 | eth0 |
| R4 | 10.0.0.4 | eth0 |

```bash
# Set per-leaf values (edit these two lines on each router)
LOCAL_LO=10.0.0.4
HOST_IF=eth0

# If the host-facing interface has an IP, remove it — it must be L2 only
ip addr flush dev $HOST_IF

# Create the VXLAN interface
#   id 10        → VNI 10
#   dstport 4789 → standard VXLAN UDP port
#   local        → tunnel source = our loopback (must match BGP next-hop)
#   nolearning   → disable kernel MAC learning, let EVPN populate the FDB
ip link add vxlan10 type vxlan id 10 dstport 4789 local $LOCAL_LO nolearning

# Create the bridge that joins the host port to the VXLAN tunnel
ip link add br10 type bridge

# Attach VXLAN and host-facing interface as bridge ports
ip link set vxlan10 master br10
ip link set $HOST_IF master br10

# Bring everything up
ip link set vxlan10 up
ip link set br10 up
ip link set $HOST_IF up
```

---

## 4. Hosts — IP configuration

```bash
# host_iantar-1
ip addr add 20.1.1.1/24 dev eth1 && ip link set eth1 up

# host_iantar-2
ip addr add 20.1.1.2/24 dev eth0 && ip link set eth0 up

# host_iantar-3
ip addr add 20.1.1.3/24 dev eth0 && ip link set eth0 up
```

---

## 5. Verification

```bash
# On any leaf — should show 1 EVPN neighbor (the RR), Established
vtysh -c "show bgp l2vpn evpn summary"

# Before any host traffic — only type 3 routes (one per VTEP)
vtysh -c "show bgp l2vpn evpn"

# Send one packet from a host to populate the MAC table
# (on host_iantar-1)
ping -c 1 20.1.1.99    # any unused IP, the ARP is what matters

# Back on the leaf — type 2 route for the host's MAC should now appear
vtysh -c "show bgp l2vpn evpn"

# What VNIs FRR has detected locally
vtysh -c "show evpn vni"

# MACs known for VNI 10 (local + remote)
vtysh -c "show evpn mac vni 10"

# Cross-leaf ping
# (on host_iantar-1) ping host_iantar-2
ping 20.1.1.2

# Confirm VXLAN encapsulation on the wire (run on a leaf's uplink)
tcpdump -i eth0 -n udp port 4789
```

---

## Note on dynamic peering

The subject asks for **dynamic** relationships on the RR. The block above uses static `neighbor 10.0.0.X` lines, which is fine for getting EVPN working first. To switch to dynamic peering on R1 once everything is verified, replace the three static neighbors with:

```bash
vtysh
configure terminal
router bgp 65000

# Remove the static neighbors
no neighbor 10.0.0.2
no neighbor 10.0.0.3
no neighbor 10.0.0.4

# Create a peer-group with shared settings
neighbor LEAFS peer-group
neighbor LEAFS remote-as 65000
neighbor LEAFS update-source lo

# Accept incoming sessions from any IP in the loopback range
bgp listen range 10.0.0.0/24 peer-group LEAFS

# Activate EVPN + RR-client on the peer-group
address-family l2vpn evpn
 neighbor LEAFS activate
 neighbor LEAFS route-reflector-client
exit-address-family

end
write memory
```