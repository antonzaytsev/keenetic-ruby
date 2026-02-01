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

- [x] Firewall Policies (`client.firewall.policies`)
- [x] Access Lists (`client.firewall.access_lists`)
- [x] Add Firewall Rule (`client.firewall.add_rule`)
- [x] Delete Firewall Rule (`client.firewall.delete_rule`)

## 12. VPN

- [x] VPN Server Status (`client.vpn.status`)
- [x] VPN Server Clients (`client.vpn.clients`)
- [x] IPsec Status (`client.vpn.ipsec_status`)
- [x] Configure VPN Server (`client.vpn.configure`)

## 13. USB & Storage

- [x] USB Devices (`client.usb.devices`)
- [x] Storage/Media (`client.usb.media`, `client.usb.storage`)
- [x] Safely Eject USB (`client.usb.eject`)

## 14. DNS

- [x] DNS Servers (`client.dns.servers`, `client.dns.name_servers`)
- [x] DNS Cache (`client.dns.cache`)
- [x] DNS Proxy Settings (`client.dns.proxy`, `client.dns.proxy_settings`)
- [x] Clear DNS Cache (`client.dns.clear_cache`)

## 15. Dynamic DNS

- [x] KeenDNS Status (`client.dyndns.keendns_status`)
- [x] Configure KeenDNS (`client.dyndns.configure_keendns`)
- [x] Third-Party DDNS (`client.dyndns.third_party`, `client.dyndns.providers`)

## 16. Schedules

- [x] List Schedules (`client.schedule.all`, `client.schedule.find`)
- [x] Create Schedule (`client.schedule.create`)
- [x] Delete Schedule (`client.schedule.delete`)

## 17. Users

- [x] List Users (`client.users.all`, `client.users.find`)
- [x] Create User (`client.users.create`)
- [x] Delete User (`client.users.delete`)

## 18. Logs

- [x] System Log (`client.logs.all`)
- [x] Filtered Log by Level (`client.logs.by_level`)
- [x] Device Events (connection/disconnection) (`client.logs.device_events`)

## 19. Diagnostics

- [x] Ping (`client.diagnostics.ping`)
- [x] Traceroute (`client.diagnostics.traceroute`)
- [x] DNS Lookup (`client.diagnostics.nslookup`, `client.diagnostics.dns_lookup`)

## 20. System Operations

- [x] Reboot (`client.system.reboot`)
- [x] Save Configuration (`client.system_config.save`)
- [x] Download Configuration (`client.system_config.download`)
- [x] Upload Configuration (`client.system_config.upload`)
- [x] Factory Reset (`client.system.factory_reset`)
- [x] Check for Updates (`client.system.check_updates`)
- [x] Apply Firmware Update (`client.system.apply_update`)
- [x] LED Control (`client.system.set_led_mode`)
- [x] Button Configuration (`client.system.button_config`)

## 20.1 Raw RCI Access

- [x] Execute RCI Command (`client.rci`)

## 21. Components

- [x] Installed Components (`client.components.installed`)
- [x] Available Components (`client.components.available`)
- [x] Install Component (`client.components.install`)
- [x] Remove Component (`client.components.remove`)

## 22. Mesh Wi-Fi System

- [x] Mesh Status (`client.mesh.status`)
- [x] Mesh Members (`client.mesh.members`)

## 23. QoS & Traffic Control

- [x] Traffic Shaper Status (`client.qos.traffic_shaper`, `client.qos.shaper`)
- [x] IntelliQoS Settings (`client.qos.intelliqos`, `client.qos.settings`)
- [x] Traffic Statistics by Host (`client.qos.traffic_stats`, `client.qos.host_stats`)

## 24. IPv6

- [x] IPv6 Interfaces (`client.ipv6.interfaces`)
- [x] IPv6 Routes (`client.ipv6.routes`)
- [x] IPv6 Neighbors (`client.ipv6.neighbors`)
