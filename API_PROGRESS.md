# Keenetic Gem API Implementation Progress

Implementation status according to [KEENETIC_API.md](./KEENETIC_API.md) specification.

---

## 1. Authentication

- [x] Challenge-response authentication
- [x] Cookie session handling
- [x] MD5 + SHA256 hash calculation

## 2. API Conventions

- [x] GET requests (`client.get`)
- [x] POST requests (`client.post`)
- [x] Batch requests (`client.batch`)
- [x] JSON parsing
- [x] Key normalization (kebab-case → snake_case)
- [x] Boolean normalization

## 3. System

- [x] System Status (`client.system.resources`)
- [x] Firmware & Hardware Info (`client.system.info`)
- [x] System Defaults (`client.system.defaults`)
- [x] License Information (`client.system.license`)

## 4. Devices & Hosts

- [x] List All Devices (`client.devices.all`)
- [x] List Active Devices (`client.devices.active`)
- [x] Find Device (`client.devices.find`)
- [x] Update Device Name (`client.devices.update` via `known.host`)
- [x] Update Device Access (`client.devices.update` via `ip.hotspot.host`)
- [x] Delete Device Registration (`client.devices.delete`)

## 5. Network Interfaces

- [x] List All Interfaces (`client.network.interfaces`)
- [x] Get Interface by ID (`client.network.interface`)
- [x] WAN Status (`client.network.wan_status`)
- [x] LAN Interfaces (`client.network.lan_interfaces`)
- [x] Interface Statistics (`client.network.statistics`, `client.network.interface_statistics`)
- [x] Configure Interface (`client.network.configure`)

## 6. Internet & WAN

- [x] Internet Status (`client.internet.status`)
- [x] WAN Speed Stats (`client.internet.speed`)
- [x] Configure WAN Connection (`client.internet.configure`)

## 7. Wi-Fi

- [x] Wi-Fi Access Points (`client.wifi.access_points`)
- [x] Wi-Fi Clients (`client.wifi.clients`)
- [x] Get Access Point by ID (`client.wifi.access_point`)
- [x] Configure Wi-Fi (`client.wifi.configure`)
- [x] Enable/Disable Wi-Fi (`client.wifi.enable`, `client.wifi.disable`)

## 8. DHCP

- [x] DHCP Leases (`client.dhcp.leases`)
- [x] Static DHCP Bindings (`client.dhcp.bindings`, `client.dhcp.find_binding`)
- [x] Add Static DHCP Binding (`client.dhcp.create_binding`)
- [x] Update Static DHCP Binding (`client.dhcp.update_binding`)
- [x] Delete Static DHCP Binding (`client.dhcp.delete_binding`)

## 9. Routing

- [x] Routing Table (`client.routing.routes`)
- [x] ARP Table (`client.routing.arp_table`)
- [x] Find Route (`client.routing.find_route`)
- [x] Find ARP Entry (`client.routing.find_arp_entry`)
- [x] Add Route (`client.routing.create_route`)
- [x] Delete Route (`client.routing.delete_route`)

## 9.0 Static Routes (Configuration)

- [x] List Static Routes (`client.routes.all`)
- [x] Add Static Route (`client.routes.add`)
- [x] Add Batch Routes (`client.routes.add_batch`)
- [x] Delete Static Route (`client.routes.delete`)
- [x] Delete Batch Routes (`client.routes.delete_batch`)
- [x] CIDR to Mask Conversion (`Keenetic::Resources::Routes.cidr_to_mask`)

## 9.1 Routing Policies

- [x] List All Policies (`client.policies.all`)
- [x] Device Policy Assignments (`client.policies.device_assignments`)
- [x] Find Policy by ID (`client.policies.find`)

## 9.2 Hotspot / IP Policies

- [x] List All IP Policies (`client.hotspot.policies`)
- [x] List All Hosts with Policies (`client.hotspot.hosts`)
- [x] Find Policy by ID (`client.hotspot.find_policy`)
- [x] Find Host by MAC (`client.hotspot.find_host`)
- [x] Set Host Policy (`client.hotspot.set_host_policy`)
- [x] Remove Host Policy (`client.hotspot.set_host_policy(policy: nil)`)

## 10. NAT & Port Forwarding

- [x] List Physical Ports (`client.ports.all`)
- [x] Find Port (`client.ports.find`)
- [x] List NAT Rules (`client.nat.rules`, `client.nat.find_rule`)
- [x] Add Port Forward (`client.nat.add_forward`)
- [x] Delete Port Forward (`client.nat.delete_forward`)
- [x] UPnP Mappings (`client.nat.upnp_mappings`)

## 11. Firewall

- [ ] Firewall Policies
- [ ] Access Lists
- [ ] Add Firewall Rule

## 12. VPN

- [x] VPN Server Status (`client.vpn.status`)
- [x] VPN Server Clients (`client.vpn.clients`)
- [x] IPsec Status (`client.vpn.ipsec_status`)
- [x] Configure VPN Server (`client.vpn.configure`)

## 13. USB & Storage

- [ ] USB Devices
- [ ] Storage/Media
- [ ] Safely Eject USB

## 14. DNS

- [ ] DNS Servers
- [ ] DNS Cache
- [ ] DNS Proxy Settings
- [ ] Clear DNS Cache

## 15. Dynamic DNS

- [ ] KeenDNS Status
- [ ] Configure KeenDNS
- [ ] Third-Party DDNS

## 16. Schedules

- [ ] List Schedules
- [ ] Create Schedule
- [ ] Delete Schedule

## 17. Users

- [ ] List Users
- [ ] Create User
- [ ] Delete User

## 18. Logs

- [x] System Log (`client.logs.all`)
- [x] Filtered Log by Level (`client.logs.by_level`)
- [x] Device Events (connection/disconnection) (`client.logs.device_events`)

## 19. Diagnostics

- [ ] Ping
- [ ] Traceroute
- [ ] DNS Lookup

## 20. System Operations

- [ ] Reboot
- [x] Save Configuration (`client.system_config.save`)
- [x] Download Configuration (`client.system_config.download`)
- [x] Upload Configuration (`client.system_config.upload`)
- [ ] Factory Reset
- [ ] Check for Updates
- [ ] Apply Firmware Update
- [ ] LED Control
- [ ] Button Configuration

## 20.1 Raw RCI Access

- [x] Execute RCI Command (`client.rci`)

## 21. Components

- [ ] Installed Components
- [ ] Available Components
- [ ] Install Component
- [ ] Remove Component

## 22. Mesh Wi-Fi System

- [ ] Mesh Status
- [ ] Mesh Members

## 23. QoS & Traffic Control

- [ ] Traffic Shaper Status
- [ ] IntelliQoS Settings
- [ ] Traffic Statistics by Host

## 24. IPv6

- [ ] IPv6 Interfaces
- [ ] IPv6 Routes
- [ ] IPv6 Neighbors
