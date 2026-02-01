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

# Connected devices
client.devices.all
client.devices.active
client.devices.find(mac: 'AA:BB:CC:DD:EE:FF')
client.devices.update(mac: 'AA:BB:CC:DD:EE:FF', name: 'My Phone')

# System info
client.system.info       # model, firmware
client.system.resources  # CPU, memory, uptime

# Network
client.network.interfaces

# WiFi
client.wifi.access_points
client.wifi.clients

# Internet
client.internet.status
client.internet.speed

# Ports
client.ports.all

# Static Routes
client.routes.all
client.routes.add(host: '1.2.3.4', interface: 'Wireguard0', comment: 'VPN host')
client.routes.add(network: '10.0.0.0/24', interface: 'Wireguard0', comment: 'VPN network')
client.routes.add_batch([
  { host: '1.2.3.4', interface: 'Wireguard0', comment: 'Host 1' },
  { network: '10.0.0.0/24', interface: 'Wireguard0', comment: 'Network 1' }
])
client.routes.delete(host: '1.2.3.4')
client.routes.delete(network: '10.0.0.0/24')

# Hotspot / Policies
client.hotspot.policies                                         # all IP policies
client.hotspot.hosts                                            # all registered hosts
client.hotspot.set_host_policy(mac: 'AA:BB:CC:DD:EE:FF', policy: 'Policy0')
client.hotspot.set_host_policy(mac: 'AA:BB:CC:DD:EE:FF', policy: nil)  # remove policy

# Configuration
client.system_config.save       # save to flash
client.system_config.download   # download startup-config.txt

# Raw RCI Access (for custom commands)
client.rci({ 'show' => { 'system' => {} } })
client.rci([
  { 'show' => { 'system' => {} } },
  { 'show' => { 'version' => {} } }
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
  # Other API errors
  e.status_code
  e.response_body
end
```

## API Reference

See [KEENETIC_API.md](KEENETIC_API.md) for complete API documentation.

## Requirements

- Ruby >= 3.0

## License

MIT
