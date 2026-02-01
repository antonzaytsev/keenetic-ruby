# Keenetic Gem API Reference

Complete documentation for all available features.

## Table of Contents

- [System](#system)
- [Devices](#devices)
- [Network Interfaces](#network-interfaces)
- [Internet & WAN](#internet--wan)
- [Wi-Fi](#wi-fi)
- [DHCP](#dhcp)
- [Routing](#routing)
- [Static Routes](#static-routes)
- [Routing Policies](#routing-policies)
- [Hotspot / IP Policies](#hotspot--ip-policies)
- [Physical Ports](#physical-ports)
- [NAT & Port Forwarding](#nat--port-forwarding)
- [VPN](#vpn)
- [Logs](#logs)
- [Configuration Management](#configuration-management)
- [Raw RCI Access](#raw-rci-access)

---

## System

System information and operations.

### `client.system.info`

Get router model, firmware, and hardware information.

```ruby
info = client.system.info
# => {
#   model: "Keenetic Viva",
#   device: "KN-1912",
#   manufacturer: "Keenetic Ltd.",
#   vendor: "Keenetic",
#   hw_version: "A",
#   firmware: "KeeneticOS",
#   firmware_version: "4.01.C.7.0-0",
#   ndm_version: "4.01.C.7.0-0",
#   arch: "mips",
#   components: ["base", "wifi", "vpn-server"]
# }
```

### `client.system.resources`

Get CPU, memory, and swap usage.

```ruby
resources = client.system.resources
# => {
#   cpu: { load_percent: 15 },
#   memory: { total: 536870912, free: 268435456, used: 215789568, used_percent: 40.2 },
#   swap: { total: 0, free: 0, used: 0, used_percent: 0 },
#   uptime: 86400
# }
```

### `client.system.uptime`

Get system uptime in seconds.

```ruby
client.system.uptime
# => 86400
```

### `client.system.defaults`

Get default system configuration values.

```ruby
defaults = client.system.defaults
# => { system_name: "Keenetic", domain_name: "local", language: "en", ... }
```

### `client.system.license`

Get license status and enabled features.

```ruby
license = client.system.license
# => {
#   valid: true,
#   active: true,
#   expires: "2025-12-31",
#   features: [{ name: "vpn-server", enabled: true }],
#   services: [{ name: "keendns", enabled: true, active: true }]
# }
```

### `client.system.reboot`

Reboot the router. All connections will be dropped.

```ruby
client.system.reboot
```

### `client.system.factory_reset`

Restore factory defaults. **Warning:** This erases all configuration!

```ruby
client.system.factory_reset
```

### `client.system.check_updates`

Check for available firmware updates.

```ruby
update = client.system.check_updates
# => {
#   available: true,
#   version: "4.2.0.0.C.0",
#   current: "4.1.0.0.C.0",
#   channel: "stable",
#   release_date: "2024-01-15"
# }
```

### `client.system.apply_update`

Download and install firmware update. Router will reboot automatically.

```ruby
client.system.apply_update
```

### `client.system.set_led_mode(mode)`

Control router LED indicators.

| Mode | Description |
|------|-------------|
| `'on'` | LEDs always on |
| `'off'` | LEDs always off |
| `'auto'` | LEDs controlled automatically |

```ruby
client.system.set_led_mode('off')
client.system.set_led_mode('auto')
```

### `client.system.button_config`

Get physical button configuration.

```ruby
buttons = client.system.button_config
# => {
#   wifi: { action: "toggle", enabled: true },
#   fn: { action: "wps", long_press: "reset" }
# }
```

---

## Devices

Manage registered devices (hosts).

### `client.devices.all`

List all registered devices.

```ruby
devices = client.devices.all
# => [
#   {
#     mac: "AA:BB:CC:DD:EE:FF",
#     name: "My Phone",
#     hostname: "iphone",
#     ip: "192.168.1.100",
#     active: true,
#     access: "permit",
#     rxbytes: 1073741824,
#     txbytes: 536870912,
#     first_seen: "2024-01-01T00:00:00Z",
#     last_seen: "2024-01-15T12:00:00Z"
#   },
#   ...
# ]
```

### `client.devices.active`

List only currently connected devices.

```ruby
active = client.devices.active
```

### `client.devices.find(mac:)`

Find a specific device by MAC address.

```ruby
device = client.devices.find(mac: 'AA:BB:CC:DD:EE:FF')
# => { mac: "AA:BB:CC:DD:EE:FF", name: "My Phone", ... }
```

### `client.devices.update(mac:, **options)`

Update device properties.

| Option | Description |
|--------|-------------|
| `name:` | Device display name |
| `access:` | Access policy: `'permit'` or `'deny'` |

```ruby
# Update device name
client.devices.update(mac: 'AA:BB:CC:DD:EE:FF', name: 'Living Room TV')

# Block device access
client.devices.update(mac: 'AA:BB:CC:DD:EE:FF', access: 'deny')

# Update both
client.devices.update(mac: 'AA:BB:CC:DD:EE:FF', name: 'Guest Phone', access: 'permit')
```

### `client.devices.delete(mac:)`

Remove device from registered list.

```ruby
client.devices.delete(mac: 'AA:BB:CC:DD:EE:FF')
```

---

## Network Interfaces

Manage network interfaces (Ethernet, Wi-Fi, bridges, tunnels).

### `client.network.interfaces`

List all network interfaces.

```ruby
interfaces = client.network.interfaces
# => {
#   "GigabitEthernet0" => { id: "GigabitEthernet0", type: "GigabitEthernet", link: true, ... },
#   "Bridge0" => { id: "Bridge0", type: "Bridge", address: "192.168.1.1", ... },
#   ...
# }
```

### `client.network.interface(id)`

Get a specific interface by ID.

```ruby
iface = client.network.interface('Bridge0')
# => { id: "Bridge0", address: "192.168.1.1", mask: "255.255.255.0", ... }
```

### `client.network.wan_status`

Get WAN interface status.

```ruby
wan = client.network.wan_status
# => { connected: true, address: "203.0.113.50", gateway: "203.0.113.1", ... }
```

### `client.network.lan_interfaces`

List LAN interfaces only.

```ruby
lan = client.network.lan_interfaces
```

### `client.network.statistics`

Get traffic statistics for all interfaces.

```ruby
stats = client.network.statistics
```

### `client.network.interface_statistics(id)`

Get traffic statistics for a specific interface.

```ruby
stats = client.network.interface_statistics('GigabitEthernet0')
# => { rxbytes: 1073741824, txbytes: 536870912, rxpackets: 1000000, ... }
```

### `client.network.configure(id, **options)`

Configure an interface.

```ruby
client.network.configure('Bridge0', description: 'Home LAN')
```

---

## Internet & WAN

Monitor and configure internet connectivity.

### `client.internet.status`

Check internet connectivity status.

```ruby
status = client.internet.status
# => {
#   internet: true,
#   gateway: "10.0.0.1",
#   dns: ["8.8.8.8", "8.8.4.4"],
#   interface: "ISP",
#   address: "203.0.113.50"
# }
```

### `client.internet.speed`

Get current WAN speed statistics.

```ruby
speed = client.internet.speed
# => { download: 94500000, upload: 47200000 }  # bits per second
```

### `client.internet.configure(interface_id, **options)`

Configure WAN connection.

```ruby
# Static IP
client.internet.configure('ISP', 
  address: '203.0.113.50',
  mask: '255.255.255.0',
  gateway: '203.0.113.1'
)
```

---

## Wi-Fi

Manage Wi-Fi access points and monitor clients.

### `client.wifi.access_points`

List all Wi-Fi access points.

```ruby
aps = client.wifi.access_points
# => [
#   {
#     id: "WifiMaster0/AccessPoint0",
#     ssid: "MyNetwork",
#     band: "2.4GHz",
#     channel: 6,
#     authentication: "wpa2-psk",
#     station_count: 5
#   },
#   ...
# ]
```

### `client.wifi.access_point(id)`

Get a specific access point.

```ruby
ap = client.wifi.access_point('WifiMaster0/AccessPoint0')
```

### `client.wifi.clients`

List connected Wi-Fi clients with signal information.

```ruby
clients = client.wifi.clients
# => [
#   {
#     mac: "AA:BB:CC:DD:EE:FF",
#     ap: "WifiMaster0/AccessPoint0",
#     rssi: -45,
#     txrate: 866700,
#     rxrate: 780000,
#     uptime: 3600
#   },
#   ...
# ]
```

### `client.wifi.configure(id, **options)`

Configure Wi-Fi access point.

| Option | Description |
|--------|-------------|
| `ssid:` | Network name |
| `key:` | Password |
| `authentication:` | Security mode |
| `channel:` | Channel number |

```ruby
client.wifi.configure('WifiMaster0/AccessPoint0',
  ssid: 'MyNetwork',
  key: 'secretpassword',
  authentication: 'wpa2-psk',
  channel: 6
)
```

### `client.wifi.enable(id)` / `client.wifi.disable(id)`

Enable or disable Wi-Fi access point.

```ruby
client.wifi.disable('WifiMaster0/AccessPoint0')
client.wifi.enable('WifiMaster0/AccessPoint0')
```

---

## DHCP

Manage DHCP leases and static bindings.

### `client.dhcp.leases`

List active DHCP leases.

```ruby
leases = client.dhcp.leases
# => [
#   { ip: "192.168.1.100", mac: "AA:BB:CC:DD:EE:FF", hostname: "iphone", expires: 1704067200 },
#   ...
# ]
```

### `client.dhcp.bindings`

List static DHCP bindings (IP reservations).

```ruby
bindings = client.dhcp.bindings
# => [
#   { mac: "AA:BB:CC:DD:EE:FF", ip: "192.168.1.100", name: "My Server" },
#   ...
# ]
```

### `client.dhcp.find_binding(mac:)`

Find a specific binding by MAC address.

```ruby
binding = client.dhcp.find_binding(mac: 'AA:BB:CC:DD:EE:FF')
```

### `client.dhcp.create_binding(mac:, ip:, name: nil)`

Create a static IP reservation.

```ruby
client.dhcp.create_binding(
  mac: 'AA:BB:CC:DD:EE:FF',
  ip: '192.168.1.100',
  name: 'Home Server'
)
```

### `client.dhcp.update_binding(mac:, ip: nil, name: nil)`

Update an existing binding.

```ruby
client.dhcp.update_binding(mac: 'AA:BB:CC:DD:EE:FF', ip: '192.168.1.101')
```

### `client.dhcp.delete_binding(mac:)`

Delete a static binding.

```ruby
client.dhcp.delete_binding(mac: 'AA:BB:CC:DD:EE:FF')
```

---

## Routing

View and manage the routing table.

### `client.routing.routes`

Get the current routing table.

```ruby
routes = client.routing.routes
# => [
#   { destination: "0.0.0.0", mask: "0.0.0.0", gateway: "10.0.0.1", interface: "ISP" },
#   { destination: "192.168.1.0", mask: "255.255.255.0", interface: "Bridge0" },
#   ...
# ]
```

### `client.routing.arp_table`

Get the ARP cache.

```ruby
arp = client.routing.arp_table
# => [
#   { ip: "192.168.1.100", mac: "AA:BB:CC:DD:EE:FF", interface: "Bridge0" },
#   ...
# ]
```

### `client.routing.find_route(destination:)`

Find a specific route.

```ruby
route = client.routing.find_route(destination: '10.0.0.0')
```

### `client.routing.find_arp_entry(ip:)` / `client.routing.find_arp_entry(mac:)`

Find an ARP entry.

```ruby
entry = client.routing.find_arp_entry(ip: '192.168.1.100')
entry = client.routing.find_arp_entry(mac: 'AA:BB:CC:DD:EE:FF')
```

### `client.routing.create_route(**options)` / `client.routing.delete_route(**options)`

Add or remove routes from the routing table.

```ruby
client.routing.create_route(
  destination: '10.0.0.0',
  mask: '255.0.0.0',
  gateway: '192.168.1.1'
)

client.routing.delete_route(destination: '10.0.0.0', mask: '255.0.0.0')
```

---

## Static Routes

Configure persistent static routes.

### `client.routes.all`

List all configured static routes.

```ruby
routes = client.routes.all
# => [
#   { network: "10.0.0.0/24", interface: "Wireguard0", comment: "VPN network" },
#   { host: "1.2.3.4", interface: "Wireguard0", comment: "VPN host" },
#   ...
# ]
```

### `client.routes.add(**options)`

Add a static route.

| Option | Description |
|--------|-------------|
| `host:` | Single host IP (e.g., `'1.2.3.4'`) |
| `network:` | Network in CIDR notation (e.g., `'10.0.0.0/24'`) |
| `interface:` | Output interface name |
| `gateway:` | Next hop IP (optional) |
| `comment:` | Route description (optional) |
| `auto:` | Auto-enable route (default: true) |

```ruby
# Route to a single host
client.routes.add(host: '1.2.3.4', interface: 'Wireguard0', comment: 'VPN server')

# Route to a network
client.routes.add(network: '10.0.0.0/24', interface: 'Wireguard0')

# Route via gateway
client.routes.add(network: '172.16.0.0/16', gateway: '192.168.1.254')
```

### `client.routes.add_batch(routes)`

Add multiple routes at once.

```ruby
client.routes.add_batch([
  { host: '1.2.3.4', interface: 'Wireguard0' },
  { host: '5.6.7.8', interface: 'Wireguard0' },
  { network: '10.0.0.0/24', interface: 'Wireguard0' }
])
```

### `client.routes.delete(**options)`

Delete a static route.

```ruby
client.routes.delete(host: '1.2.3.4')
client.routes.delete(network: '10.0.0.0/24')
```

### `client.routes.delete_batch(routes)`

Delete multiple routes at once.

```ruby
client.routes.delete_batch([
  { host: '1.2.3.4' },
  { network: '10.0.0.0/24' }
])
```

---

## Routing Policies

View routing policies (VPN routing, multi-WAN).

### `client.policies.all`

List all routing policies.

```ruby
policies = client.policies.all
# => [
#   {
#     id: "Policy0",
#     description: "Latvia VPN",
#     permit: [
#       { interface: "Wireguard0", enabled: true },
#       { interface: "ISP", enabled: false }
#     ]
#   },
#   ...
# ]
```

### `client.policies.find(id)`

Find a policy by ID.

```ruby
policy = client.policies.find('Policy0')
```

### `client.policies.device_assignments`

Get device-to-policy assignments.

```ruby
assignments = client.policies.device_assignments
# => [
#   { mac: "AA:BB:CC:DD:EE:FF", policy: "Policy0" },
#   ...
# ]
```

---

## Hotspot / IP Policies

Manage host access policies.

### `client.hotspot.policies`

List all IP policies.

```ruby
policies = client.hotspot.policies
```

### `client.hotspot.hosts`

List all hosts with policy assignments.

```ruby
hosts = client.hotspot.hosts
# => [
#   { mac: "AA:BB:CC:DD:EE:FF", policy: "Policy0", permit: true },
#   ...
# ]
```

### `client.hotspot.find_policy(id)`

Find a policy by ID.

```ruby
policy = client.hotspot.find_policy('Policy0')
```

### `client.hotspot.find_host(mac:)`

Find a host by MAC address.

```ruby
host = client.hotspot.find_host(mac: 'AA:BB:CC:DD:EE:FF')
```

### `client.hotspot.set_host_policy(mac:, policy:)`

Assign or remove a policy from a host.

```ruby
# Assign policy
client.hotspot.set_host_policy(mac: 'AA:BB:CC:DD:EE:FF', policy: 'Policy0')

# Remove policy
client.hotspot.set_host_policy(mac: 'AA:BB:CC:DD:EE:FF', policy: nil)
```

---

## Physical Ports

Monitor physical Ethernet port status.

### `client.ports.all`

List all physical ports.

```ruby
ports = client.ports.all
# => [
#   {
#     id: "GigabitEthernet0",
#     port: 0,
#     type: "gigabit",
#     link: true,
#     speed: 1000,
#     duplex: "full",
#     rxbytes: 1073741824,
#     txbytes: 536870912
#   },
#   ...
# ]
```

### `client.ports.find(id)`

Find a specific port.

```ruby
port = client.ports.find('GigabitEthernet0')
```

---

## NAT & Port Forwarding

Manage NAT rules and port forwarding.

### `client.nat.rules`

List all NAT/port forwarding rules.

```ruby
rules = client.nat.rules
# => [
#   {
#     index: 1,
#     description: "Web Server",
#     protocol: "tcp",
#     interface: "ISP",
#     port: 8080,
#     to_host: "192.168.1.100",
#     to_port: 80,
#     enabled: true
#   },
#   ...
# ]
```

### `client.nat.find_rule(index)`

Find a rule by index.

```ruby
rule = client.nat.find_rule(1)
```

### `client.nat.add_forward(**options)`

Create a port forwarding rule.

| Option | Required | Description |
|--------|----------|-------------|
| `index:` | Yes | Rule priority/index |
| `protocol:` | Yes | `'tcp'`, `'udp'`, or `'any'` |
| `port:` | Yes | External port |
| `to_host:` | Yes | Internal host IP |
| `to_port:` | Yes | Internal port |
| `interface:` | No | WAN interface (default: `'ISP'`) |
| `description:` | No | Rule description |
| `end_port:` | No | End of port range |
| `enabled:` | No | Enable rule (default: `true`) |

```ruby
# Simple port forward
client.nat.add_forward(
  index: 1,
  protocol: 'tcp',
  port: 8080,
  to_host: '192.168.1.100',
  to_port: 80,
  description: 'Web Server'
)

# Port range
client.nat.add_forward(
  index: 2,
  protocol: 'udp',
  port: 27015,
  end_port: 27030,
  to_host: '192.168.1.50',
  to_port: 27015,
  description: 'Game Server'
)
```

### `client.nat.delete_forward(index:)`

Delete a port forwarding rule.

```ruby
client.nat.delete_forward(index: 1)
```

### `client.nat.upnp_mappings`

List automatic UPnP port mappings.

```ruby
mappings = client.nat.upnp_mappings
# => [
#   {
#     protocol: "tcp",
#     port: 51413,
#     to_host: "192.168.1.50",
#     to_port: 51413,
#     description: "Transmission"
#   },
#   ...
# ]
```

---

## VPN

Manage VPN server and monitor connections.

### `client.vpn.status`

Get VPN server status and configuration.

```ruby
status = client.vpn.status
# => {
#   type: "l2tp",
#   enabled: true,
#   running: true,
#   pool_start: "192.168.1.200",
#   pool_end: "192.168.1.210",
#   interface: "PPTP0"
# }
```

### `client.vpn.clients`

List connected VPN clients.

```ruby
clients = client.vpn.clients
# => [
#   {
#     name: "user1",
#     ip: "192.168.1.200",
#     uptime: 3600,
#     rxbytes: 1048576,
#     txbytes: 524288
#   },
#   ...
# ]
```

### `client.vpn.ipsec_status`

Get IPsec security associations.

```ruby
ipsec = client.vpn.ipsec_status
# => {
#   established: 2,
#   sa: [
#     { name: "tunnel-1", state: "established", local_id: "192.168.1.1", remote_id: "10.0.0.1" },
#     ...
#   ]
# }
```

### `client.vpn.configure(**options)`

Configure VPN server.

| Option | Required | Description |
|--------|----------|-------------|
| `type:` | Yes | VPN type: `'pptp'`, `'l2tp'`, `'sstp'` |
| `enabled:` | Yes | Enable/disable server |
| `pool_start:` | No | Client IP pool start |
| `pool_end:` | No | Client IP pool end |
| `mppe:` | No | MPPE encryption: `'require'`, `'prefer'`, `'none'` |

```ruby
# Enable L2TP server
client.vpn.configure(
  type: 'l2tp',
  enabled: true,
  pool_start: '192.168.1.200',
  pool_end: '192.168.1.210'
)

# Disable VPN server
client.vpn.configure(type: 'pptp', enabled: false)
```

---

## Logs

Access system logs.

### `client.logs.all`

Get system log entries.

```ruby
logs = client.logs.all
# => [
#   { time: "2024-01-15T12:00:00Z", level: "info", message: "System started", facility: "ndm" },
#   ...
# ]
```

### `client.logs.by_level(level)`

Filter logs by level.

| Level | Description |
|-------|-------------|
| `'error'` | Error messages |
| `'warning'` | Warnings |
| `'info'` | Informational |
| `'debug'` | Debug messages |

```ruby
errors = client.logs.by_level('error')
```

### `client.logs.device_events`

Get device connection/disconnection events.

```ruby
events = client.logs.device_events
# => [
#   { time: "...", mac: "AA:BB:CC:DD:EE:FF", event: "connected", ip: "192.168.1.100" },
#   ...
# ]
```

---

## Configuration Management

Backup and restore router configuration.

### `client.system_config.save`

Save current configuration to persistent storage.

```ruby
client.system_config.save
```

### `client.system_config.download`

Download configuration backup.

```ruby
config_text = client.system_config.download
File.write('router-backup.txt', config_text)
```

### `client.system_config.upload(content)`

Restore configuration from backup. **Warning:** Configuration is applied after reboot.

```ruby
config_text = File.read('router-backup.txt')
client.system_config.upload(config_text)
client.system.reboot  # Apply configuration
```

---

## Raw RCI Access

Execute arbitrary RCI commands for advanced usage.

### `client.rci(body)`

Execute RCI commands directly.

```ruby
# Single read command
result = client.rci({ 'show' => { 'system' => {} } })

# Batch read commands
results = client.rci([
  { 'show' => { 'system' => {} } },
  { 'show' => { 'version' => {} } }
])

# Write command
client.rci([
  { 'ip' => { 'hotspot' => { 'host' => { 'mac' => 'aa:bb:cc:dd:ee:ff', 'permit' => true } } } }
])

# Complex batch with read and write
client.rci([
  { 'known' => { 'host' => { 'mac' => 'aa:bb:cc:dd:ee:ff', 'name' => 'My Device' } } },
  { 'ip' => { 'hotspot' => { 'host' => { 'mac' => 'aa:bb:cc:dd:ee:ff', 'permit' => true } } } },
  { 'system' => { 'configuration' => { 'save' => {} } } }
])
```
