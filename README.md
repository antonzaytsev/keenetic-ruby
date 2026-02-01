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

## Quick Start

```ruby
client = Keenetic.client

# System info
client.system.info              # model, firmware
client.system.resources         # CPU, memory, uptime

# Connected devices
client.devices.all              # all registered devices
client.devices.active           # currently connected

# Network
client.network.interfaces       # all interfaces
client.wifi.access_points       # Wi-Fi networks
client.internet.status          # internet connectivity

# Port forwarding
client.nat.rules                # NAT rules
client.nat.add_forward(index: 1, protocol: 'tcp', port: 8080, 
                       to_host: '192.168.1.100', to_port: 80)

# VPN
client.vpn.status               # VPN server status
client.vpn.clients              # connected VPN clients

# Configuration
client.system_config.save       # save to flash
client.system_config.download   # backup config
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
rescue Keenetic::ApiError => e
  # other API errors
  e.status_code
  e.response_body
end
```

## Documentation

- [Complete API Reference](docs/API_REFERENCE.md) - All features with detailed examples
- [API Coverage](API_PROGRESS.md) - Implementation status
- [Keenetic API Specification](KEENETIC_API.md) - Raw API documentation

## Requirements

- Ruby >= 3.0

## License

MIT
