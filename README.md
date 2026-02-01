# Keenetic

Ruby wrapper for the Keenetic router RCI (Remote Command Interface) — the same API that powers the Keenetic web UI.

## Installation

```ruby
gem 'keenetic'
```

## Configuration

```ruby
Keenetic.configure do |config|
  config.host = '192.168.1.1'
  config.login = 'admin'
  config.password = 'your_password'
  config.timeout = 30               # optional
  config.logger = Logger.new($stdout) # optional
end
```

## Usage

```ruby
client = Keenetic.client
```

### System

```ruby
client.system.info              # model, firmware, hardware info
client.system.resources         # CPU, memory, swap, uptime
client.system.uptime            # uptime in seconds
client.system.defaults          # default configuration values
client.system.license           # license status and features

# System Operations
client.system.reboot            # restart the router
client.system.factory_reset     # restore factory defaults (use with caution!)
client.system.check_updates     # check for firmware updates
client.system.apply_update      # download and install firmware update
client.system.set_led_mode('off')  # LED control: 'on', 'off', 'auto'
client.system.button_config     # physical button configuration
```

### Devices

```ruby
client.devices.all              # all registered devices
client.devices.active           # currently connected devices
client.devices.find(mac: 'AA:BB:CC:DD:EE:FF')
client.devices.update(mac: 'AA:BB:CC:DD:EE:FF', name: 'My Phone')
client.devices.update(mac: 'AA:BB:CC:DD:EE:FF', access: 'permit')  # or 'deny'
client.devices.delete(mac: 'AA:BB:CC:DD:EE:FF')
```

### Network Interfaces

```ruby
client.network.interfaces       # all network interfaces
client.network.interface('Bridge0')  # specific interface
client.network.wan_status       # WAN connection status
client.network.lan_interfaces   # LAN interfaces only
client.network.statistics       # traffic statistics for all interfaces
client.network.interface_statistics('GigabitEthernet0')
client.network.configure('Bridge0', description: 'Home LAN')
```

### Internet & WAN

```ruby
client.internet.status          # internet connectivity status
client.internet.speed           # WAN speed statistics
client.internet.configure('ISP', address: '192.168.0.2', gateway: '192.168.0.1')
```

### Wi-Fi

```ruby
client.wifi.access_points       # all Wi-Fi access points
client.wifi.clients             # connected Wi-Fi clients with signal info
client.wifi.access_point('WifiMaster0/AccessPoint0')
client.wifi.configure('WifiMaster0/AccessPoint0', ssid: 'MyNetwork', key: 'password')
client.wifi.enable('WifiMaster0/AccessPoint0')
client.wifi.disable('WifiMaster0/AccessPoint0')
```

### DHCP

```ruby
client.dhcp.leases              # active DHCP leases
client.dhcp.bindings            # static IP reservations
client.dhcp.find_binding(mac: 'AA:BB:CC:DD:EE:FF')
client.dhcp.create_binding(mac: 'AA:BB:CC:DD:EE:FF', ip: '192.168.1.100', name: 'Server')
client.dhcp.update_binding(mac: 'AA:BB:CC:DD:EE:FF', ip: '192.168.1.101')
client.dhcp.delete_binding(mac: 'AA:BB:CC:DD:EE:FF')
```

### Routing

```ruby
# Runtime routing table
client.routing.routes           # current routing table
client.routing.arp_table        # ARP cache
client.routing.find_route(destination: '10.0.0.0')
client.routing.find_arp_entry(ip: '192.168.1.100')
client.routing.create_route(destination: '10.0.0.0', mask: '255.0.0.0', gateway: '192.168.1.1')
client.routing.delete_route(destination: '10.0.0.0', mask: '255.0.0.0')

# Static routes configuration
client.routes.all               # configured static routes
client.routes.add(host: '1.2.3.4', interface: 'Wireguard0', comment: 'VPN host')
client.routes.add(network: '10.0.0.0/24', interface: 'Wireguard0')
client.routes.add_batch([
  { host: '1.2.3.4', interface: 'Wireguard0' },
  { network: '10.0.0.0/24', interface: 'Wireguard0' }
])
client.routes.delete(host: '1.2.3.4')
client.routes.delete_batch([{ host: '1.2.3.4' }, { network: '10.0.0.0/24' }])
```

### Routing Policies

```ruby
client.policies.all             # all routing policies (VPN, etc.)
client.policies.find('Policy0')
client.policies.device_assignments  # which devices use which policies
```

### Hotspot / IP Policies

```ruby
client.hotspot.policies         # all IP policies
client.hotspot.hosts            # all hosts with policy assignments
client.hotspot.find_policy('Policy0')
client.hotspot.find_host(mac: 'AA:BB:CC:DD:EE:FF')
client.hotspot.set_host_policy(mac: 'AA:BB:CC:DD:EE:FF', policy: 'Policy0')
client.hotspot.set_host_policy(mac: 'AA:BB:CC:DD:EE:FF', policy: nil)  # remove policy
```

### Physical Ports

```ruby
client.ports.all                # physical Ethernet port statuses
client.ports.find('GigabitEthernet0')
```

### NAT & Port Forwarding

```ruby
client.nat.rules                # all port forwarding rules
client.nat.find_rule(1)         # find rule by index
client.nat.add_forward(
  index: 1,
  protocol: 'tcp',
  port: 8080,
  to_host: '192.168.1.100',
  to_port: 80,
  description: 'Web Server'
)
client.nat.delete_forward(index: 1)
client.nat.upnp_mappings        # automatic UPnP port mappings
```

### VPN

```ruby
client.vpn.status               # VPN server status and configuration
client.vpn.clients              # connected VPN clients
client.vpn.ipsec_status         # IPsec security associations
client.vpn.configure(
  type: 'l2tp',
  enabled: true,
  pool_start: '192.168.1.200',
  pool_end: '192.168.1.210'
)
```

### Logs

```ruby
client.logs.all                 # system log
client.logs.by_level('error')   # filter by level: 'error', 'warning', 'info', 'debug'
client.logs.device_events       # device connection/disconnection events
```

### Configuration Management

```ruby
client.system_config.save       # save configuration to flash
config = client.system_config.download  # download startup-config.txt
client.system_config.upload(config)     # restore configuration from backup
```

### Raw RCI Access

For advanced usage or features not yet wrapped:

```ruby
# Single command
client.rci({ 'show' => { 'system' => {} } })

# Batch commands
client.rci([
  { 'show' => { 'system' => {} } },
  { 'show' => { 'version' => {} } }
])

# Write commands
client.rci([
  { 'ip' => { 'hotspot' => { 'host' => { 'mac' => 'aa:bb:cc:dd:ee:ff', 'permit' => true } } } }
])
```

## Error Handling

```ruby
begin
  client.devices.all
rescue Keenetic::AuthenticationError
  # invalid credentials
rescue Keenetic::ConnectionError
  # router unreachable
rescue Keenetic::TimeoutError
  # request timed out
rescue Keenetic::NotFoundError
  # resource not found
rescue Keenetic::ApiError => e
  # other API errors
  e.status_code
  e.response_body
end
```

## API Coverage

See [API_PROGRESS.md](API_PROGRESS.md) for implementation status and [KEENETIC_API.md](KEENETIC_API.md) for complete API documentation.

## Requirements

- Ruby >= 3.0

## License

MIT
