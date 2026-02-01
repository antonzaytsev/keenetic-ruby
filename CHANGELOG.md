# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

#### NAT & Port Forwarding
- `client.nat.rules` - List all NAT/port forwarding rules
- `client.nat.find_rule(index)` - Find a specific NAT rule by index
- `client.nat.add_forward(...)` - Create a new port forwarding rule
- `client.nat.delete_forward(index:)` - Delete a port forwarding rule
- `client.nat.upnp_mappings` - List automatic UPnP port mappings

#### VPN
- `client.vpn.status` - Get VPN server status and configuration
- `client.vpn.clients` - List connected VPN clients
- `client.vpn.ipsec_status` - Get IPsec security associations status
- `client.vpn.configure(...)` - Configure VPN server (type, enabled, pool range)

#### System Operations
- `client.system.reboot` - Reboot the router
- `client.system.factory_reset` - Restore factory defaults
- `client.system.check_updates` - Check for available firmware updates
- `client.system.apply_update` - Download and install firmware update
- `client.system.set_led_mode(mode)` - Control LED mode (on/off/auto)
- `client.system.button_config` - Get physical button configuration

#### Configuration Management
- `client.system_config.upload(content)` - Upload and restore configuration backup

## [0.2.0] - 2025-01-XX

### Added

#### Static Routes
- `client.routes.all` - List all static routes
- `client.routes.add(...)` - Add a static route
- `client.routes.add_batch([...])` - Add multiple routes at once
- `client.routes.delete(...)` - Delete a static route
- `client.routes.delete_batch([...])` - Delete multiple routes at once
- `Keenetic::Resources::Routes.cidr_to_mask(cidr)` - CIDR to subnet mask conversion

#### Hotspot / IP Policies
- `client.hotspot.policies` - List all IP policies
- `client.hotspot.hosts` - List all hosts with policy assignments
- `client.hotspot.find_policy(id)` - Find policy by ID
- `client.hotspot.find_host(mac:)` - Find host by MAC address
- `client.hotspot.set_host_policy(mac:, policy:)` - Assign policy to host

#### Configuration Management
- `client.system_config.save` - Save configuration to persistent storage
- `client.system_config.download` - Download startup configuration backup

#### Raw RCI Access
- `client.rci(body)` - Execute arbitrary RCI commands for advanced usage

### Changed
- Improved documentation for all resources
- Added comprehensive API progress tracking

## [0.1.0] - 2025-01-XX

### Added

#### Core
- Challenge-response authentication with MD5 + SHA256
- Cookie session handling
- GET/POST/Batch request support
- JSON parsing with key normalization (kebab-case to snake_case)
- Boolean value normalization

#### System
- `client.system.resources` - CPU, memory, swap usage
- `client.system.info` - Model, firmware, hardware info
- `client.system.uptime` - System uptime
- `client.system.defaults` - Default configuration values
- `client.system.license` - License status and features

#### Devices & Hosts
- `client.devices.all` - List all registered devices
- `client.devices.active` - List active/connected devices
- `client.devices.find(mac:)` - Find device by MAC address
- `client.devices.update(mac:, ...)` - Update device name/access
- `client.devices.delete(mac:)` - Delete device registration

#### Network Interfaces
- `client.network.interfaces` - List all network interfaces
- `client.network.interface(id)` - Get specific interface
- `client.network.wan_status` - WAN connection status
- `client.network.lan_interfaces` - List LAN interfaces
- `client.network.statistics` - Interface traffic statistics
- `client.network.configure(id, ...)` - Configure interface

#### Internet & WAN
- `client.internet.status` - Internet connectivity status
- `client.internet.speed` - WAN speed statistics
- `client.internet.configure(...)` - Configure WAN connection

#### Wi-Fi
- `client.wifi.access_points` - List Wi-Fi access points
- `client.wifi.clients` - List connected Wi-Fi clients
- `client.wifi.access_point(id)` - Get specific access point
- `client.wifi.configure(id, ...)` - Configure Wi-Fi settings
- `client.wifi.enable(id)` / `client.wifi.disable(id)` - Toggle Wi-Fi

#### DHCP
- `client.dhcp.leases` - List active DHCP leases
- `client.dhcp.bindings` - List static DHCP bindings
- `client.dhcp.find_binding(mac:)` - Find binding by MAC
- `client.dhcp.create_binding(...)` - Create static binding
- `client.dhcp.update_binding(...)` - Update static binding
- `client.dhcp.delete_binding(mac:)` - Delete static binding

#### Routing
- `client.routing.routes` - Get routing table
- `client.routing.arp_table` - Get ARP cache
- `client.routing.find_route(...)` - Find specific route
- `client.routing.find_arp_entry(...)` - Find ARP entry
- `client.routing.create_route(...)` - Add route
- `client.routing.delete_route(...)` - Delete route

#### Routing Policies
- `client.policies.all` - List routing policies
- `client.policies.device_assignments` - Device policy assignments
- `client.policies.find(id)` - Find policy by ID

#### Physical Ports
- `client.ports.all` - List physical port statuses
- `client.ports.find(id)` - Find specific port

#### Logs
- `client.logs.all` - Get system log
- `client.logs.by_level(level)` - Filter log by level
- `client.logs.device_events` - Device connection/disconnection events
