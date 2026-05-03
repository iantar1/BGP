# BADASS Project — Step-by-Step Task List

> **BGP At Doors of Autonomous Systems is Simple (BADASS)**
> Network administration project using GNS3 + Docker + VXLAN + BGP EVPN

---

## 📚 Concepts to Study Before Starting

Before touching any tool, read and understand the following:

- **BGP (Border Gateway Protocol)** — RFC 4271: how it works, peer sessions, AS numbers, route advertisement
- **MP-BGP (Multiprotocol BGP)** — RFC 4760: BGP extensions to carry multiple address families (IPv4, IPv6, L3 VPN, EVPN)
- **EVPN (Ethernet VPN)** — RFC 7432: MAC address learning and advertisement over BGP; EVPN route types (Type 2: MAC/IP, Type 3: Inclusive Multicast)
- **VXLAN (Virtual Extensible LAN)** — RFC 7348: Layer 2 overlay over Layer 3, VXLAN Network Identifier (VNI), VTEP (VXLAN Tunnel Endpoint)
- **OSPF** — Open Shortest Path First: link-state IGP used to establish underlay routing between VTEPs
- **Route Reflection (RR)** — BGP technique to avoid full-mesh iBGP; one router reflects routes to all peers
- **IS-IS** — another link-state routing protocol (required in Part 1's router image)
- **GNS3** — network simulation tool; understand how to create topologies, use Docker containers, connect nodes, and export projects
- **Docker** — how to write Dockerfiles, build images, run containers with specific services
- **FRRouting (FRR)** — open-source routing suite providing zebra, bgpd, ospfd, isisd daemons
- **busybox** — minimal Unix utilities, used as base for host image
- **Bridge (br0)** — Linux software bridge; used to connect VXLAN to host interfaces
- **VTEP** — the router/leaf that encapsulates/decapsulates VXLAN traffic
- **VNI (VXLAN Network Identifier)** — the VXLAN ID (use **10** throughout this project)

---

## ✅ Part 1 — GNS3 Configuration with Docker

**Goal:** Set up GNS3 with two custom Docker images and verify both containers are reachable.

### Environment Setup
- [ ] Install a **virtual machine** (e.g., VirtualBox or VMware) — the entire project must run inside it
- [ ] Install **Docker** inside the VM
- [ ] Install **GNS3** inside the VM and configure it to use Docker

### Docker Image 1 — Host Image
- [ ] Create a `Dockerfile` for the host image:
  - Based on **Alpine Linux** (or another lightweight distro)
  - Must include **busybox** (or equivalent)
  - No IP address configured by default
- [ ] Build the image: `docker build -t host_<yourlogin> .`
- [ ] Test the image locally (run container, check busybox works)

### Docker Image 2 — Router Image
- [ ] Create a `Dockerfile` for the router image containing:
  - A routing software stack: **FRRouting (FRR)** or **Quagga** (FRR is recommended)
  - Service **BGPD** — active and configured
  - Service **OSPFD** — active and configured
  - **IS-IS routing engine** (isisd) — active
  - **busybox** or equivalent
  - No IP address configured by default
- [ ] Build the image: `docker build -t routeur_<yourlogin> .`
- [ ] Test that all daemons start correctly (`ps` should show zebra, bgpd, ospfd, isisd)

### GNS3 Topology
- [ ] Import both Docker images into GNS3
- [ ] Create a topology with:
  - 1 host node: `host_<yourlogin>-1`
  - 1 router node: `routeur_<yourlogin>`
  - Connect them together
- [ ] Verify you can connect to **both** nodes via GNS3 console (telnet)
- [ ] Name each piece of equipment using **your login** (e.g., `host_wil-1`, `routeur_wil`)

### Submission — P1
- [ ] Create a `P1/` folder at the root of your git repository
- [ ] Add configuration files with **comments** explaining each setup
- [ ] Export the GNS3 project as a **ZIP** (File → Export Portable Project, include base images)
  - File should be named `P1.gns3project` (it will be a Zip archive)
- [ ] Commit everything to git

---

## ✅ Part 2 — Discovering a VXLAN

**Goal:** Build a VXLAN network (ID 10) first in static mode, then in dynamic multicast mode.

### Topology to Build
```
         Switch_<login>
        /              \
routeur_<login>-1    routeur_<login>-2
       |                     |
  host_<login>-1        host_<login>-2
```
- 2 routers, 1 switch, 2 hosts — all named with your login

### VXLAN Static Mode
- [ ] On each router, configure the VXLAN interface:
  - VXLAN **ID = 10**, name it `vxlan10`
  - Create a **bridge `br0`** and add the VXLAN and the LAN-facing interface to it
  - Configure Ethernet interfaces as needed (any addressing you prefer)
  - Example command: `ip link add vxlan10 type vxlan id 10 ...`
- [ ] Assign IP addresses to hosts (e.g., `30.1.1.1/24` and `30.1.1.2/24`)
- [ ] Verify connectivity: `ping` from one host to the other through the VXLAN
- [ ] Capture traffic in GNS3/Wireshark and confirm:
  - VXLAN header is present (VNI = 10)
  - Inner ICMP packets are visible

### VXLAN Dynamic Multicast Mode
- [ ] Reconfigure the VXLAN to use a **multicast group** (e.g., `239.1.1.1`, modifiable)
  - Example: `ip link add vxlan10 type vxlan id 10 group 239.1.1.1 dev eth0`
- [ ] Confirm multicast is working (traffic shows BROADCAST/MULTICAST in `ifconfig`)
- [ ] Check the **MAC address table** on both routers: `brctl showmacs br0`
  - Should show learned MAC addresses from both sides

### Submission — P2
- [ ] Create a `P2/` folder at the root of your git repository
- [ ] Add config files for each piece of equipment (with comments)
- [ ] Expected files (using your login, e.g., `wil`):
  - `P2.gns3project` (ZIP)
  - `_wil-1_g`, `_wil-1_host`, `_wil-1_s`
  - `_wil-2_g`, `_wil-2_host`, `_wil-2_s`
- [ ] Export project as ZIP including base images
- [ ] Commit to git

---

## ✅ Part 3 — Discovering BGP with EVPN

**Goal:** Build a small data center topology using BGP EVPN with route reflection (no MPLS), using VXLAN ID 10. MAC addresses are learned automatically.

### Topology to Build
```
            _wil-1  ← Route Reflector (RR)
           /   |   \
       e0     e1    e2
       /       |     \
  _wil-2    _wil-3   _wil-4   ← Leaves / VTEPs
     |          |        |
host_wil-1  host_wil-2  host_wil-3
```
- 1 RR router, 3 VTEP leaf routers, 3 hosts
- All named with your login

### OSPF Underlay (on all routers)
- [ ] Configure **OSPF** on all router interfaces to provide IP reachability between all nodes
- [ ] Assign **loopback IPs** to each router (e.g., `1.1.1.1/32`, `1.1.1.2/32`, etc.) — these become router IDs and VTEP IPs
- [ ] Verify OSPF is converged: `show ip route` should show all loopback routes via OSPF on every node

### BGP EVPN — Route Reflector (_wil-1)
- [ ] Configure BGP on the RR:
  - AS number (e.g., AS 1)
  - Set router-id to its loopback IP
  - Enable address family `l2vpn evpn`
  - Set each leaf as a neighbor with `route-reflector-client`
  - Enable `neighbor <IP> activate` and `advertise-all-vni`

### BGP EVPN — Leaf VTEPs (_wil-2, _wil-3, _wil-4)
- [ ] Configure BGP on each leaf:
  - Same AS number
  - Set router-id to its loopback IP
  - Peer only with the RR (`neighbor 1.1.1.1`)
  - Enable address family `l2vpn evpn`, activate neighbor, `advertise-all-vni`
- [ ] Configure VXLAN interface on each leaf (VNI = 10)
- [ ] Configure bridge `br0` with VXLAN and host-facing interface

### Verification Steps
- [ ] On any leaf, run `show ip route` — should see all VTEP loopbacks via OSPF
- [ ] Run `show bgp summary` — should show RR as the single neighbor with EVPN prefixes
- [ ] Run `show bgp l2vpn evpn` — with no hosts active, should see only **Type 3** (IMET) routes
- [ ] Start `host_wil-1` — verify its VTEP (`_wil-2`) auto-discovers the MAC address **without assigning an IP**
- [ ] Confirm **Type 2** (MAC/IP) route is created in `show bgp l2vpn evpn`
- [ ] Check from another VTEP (`_wil-4`) — it should also see the Type 2 route propagated via RR
- [ ] Start `host_wil-3` — verify a second Type 2 route appears
- [ ] Ping between hosts and confirm:
  - ICMP packets flow through the VXLAN (VNI = 10 visible in Wireshark)
  - OSPF Hello packets are visible in the capture

### Submission — P3
- [ ] Create a `P3/` folder at the root of your git repository
- [ ] Add config files for each piece of equipment (with comments):
  - `P3.gns3project` (ZIP)
  - `_wil-1`, `_wil-2`, `_wil-3`, `_wil-4`
  - `_wil-1_host`, `_wil-2_host`, `_wil-3_host`
- [ ] Export project as ZIP including base images
- [ ] Commit to git

---

## 📁 Final Repository Structure

```
./
├── P1/
│   ├── P1.gns3project      ← ZIP with base images
│   ├── _<login>-1_host     ← host config with comments
│   └── _<login>-2          ← router config with comments
├── P2/
│   ├── P2.gns3project
│   ├── _<login>-1_g
│   ├── _<login>-1_host
│   ├── _<login>-1_s
│   ├── _<login>-2_g
│   ├── _<login>-2_host
│   └── _<login>-2_s
└── P3/
    ├── P3.gns3project
    ├── _<login>-1
    ├── _<login>-1_host
    ├── _<login>-2
    ├── _<login>-2_host
    ├── _<login>-3
    ├── _<login>-3_host
    └── _<login>-4
```

> Replace `<login>` with your actual 42 login throughout all filenames and equipment names.

---

## ⚠️ Key Reminders

- All work must be done inside a **virtual machine**
- **No default IP addresses** in any Docker image
- Every piece of equipment must include **your login** in its name
- All GNS3 projects must be exported as **ZIP with base images included**
- Study each term in the subject — you will be asked to explain them during the evaluation
- Evaluation happens on **your own computer**