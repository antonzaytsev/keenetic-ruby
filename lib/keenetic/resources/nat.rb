module Keenetic
  module Resources
    # NAT resource for managing port forwarding rules.
    #
    # == API Endpoints Used
    #
    # === Reading NAT Rules
    #   GET /rci/show/ip/nat
    #   Returns: Array of port forwarding rules
    #
    # === Adding Port Forward
    #   POST /rci/ip/nat
    #   Body: { index, description, protocol, interface, port, to-host, to-port, enabled }
    #
    # === Deleting Port Forward
    #   POST /rci/ip/nat
    #   Body: { index, no: true }
    #
    # === Reading UPnP Mappings
    #   GET /rci/show/upnp/redirect
    #   Returns: Array of automatic UPnP port mappings
    #
    class Nat < Base
      # Get all NAT/port forwarding rules.
      #
      # == Keenetic API Request
      #   GET /rci/show/ip/nat
      #
      # == Response Fields
      #   - index: Rule index/priority
      #   - description: Rule description
      #   - protocol: "tcp", "udp", or "any"
      #   - interface: WAN interface
      #   - port: External port
      #   - end_port: End of port range (optional)
      #   - to_host: Internal host IP
      #   - to_port: Internal port
      #   - enabled: Rule is active
      #
      # @return [Array<Hash>] List of normalized NAT rules
      # @example
      #   rules = client.nat.rules
      #   # => [{ index: 1, description: "Web Server", protocol: "tcp", port: 8080, ... }]
      #
      def rules
        response = get('/rci/show/ip/nat')
        normalize_rules(response)
      end

      # Find a NAT rule by index.
      #
      # @param index [Integer] Rule index
      # @return [Hash, nil] Rule data or nil if not found
      # @example
      #   rule = client.nat.find_rule(1)
      #   # => { index: 1, description: "Web Server", ... }
      #
      def find_rule(index)
        rules.find { |r| r[:index] == index }
      end

      # Add a port forwarding rule.
      #
      # == Keenetic API Request
      #   POST /rci/ip/nat
      #   Body: { index, description, protocol, interface, port, to-host, to-port, enabled }
      #
      # @param index [Integer] Rule index/priority
      # @param protocol [String] Protocol: "tcp", "udp", or "any"
      # @param port [Integer] External port
      # @param to_host [String] Internal host IP address
      # @param to_port [Integer] Internal port
      # @param interface [String] WAN interface name (default: "ISP")
      # @param description [String, nil] Optional rule description
      # @param end_port [Integer, nil] End of port range (optional)
      # @param enabled [Boolean] Whether rule is active (default: true)
      # @return [Hash, Array, nil] API response
      #
      # @example Add simple port forward
      #   client.nat.add_forward(
      #     index: 1,
      #     protocol: 'tcp',
      #     port: 8080,
      #     to_host: '192.168.1.100',
      #     to_port: 80
      #   )
      #
      # @example Add port range forward
      #   client.nat.add_forward(
      #     index: 2,
      #     protocol: 'udp',
      #     port: 27015,
      #     end_port: 27030,
      #     to_host: '192.168.1.50',
      #     to_port: 27015,
      #     description: 'Game Server'
      #   )
      #
      def add_forward(index:, protocol:, port:, to_host:, to_port:, interface: 'ISP',
                      description: nil, end_port: nil, enabled: true)
        params = {
          'index' => index,
          'protocol' => protocol,
          'interface' => interface,
          'port' => port,
          'to-host' => to_host,
          'to-port' => to_port,
          'enabled' => enabled
        }
        params['description'] = description if description
        params['end-port'] = end_port if end_port

        post('/rci/ip/nat', params)
      end

      # Delete a port forwarding rule.
      #
      # == Keenetic API Request
      #   POST /rci/ip/nat
      #   Body: { index, no: true }
      #
      # @param index [Integer] Rule index to delete
      # @return [Hash, Array, nil] API response
      #
      # @example
      #   client.nat.delete_forward(index: 1)
      #
      def delete_forward(index:)
        post('/rci/ip/nat', { 'index' => index, 'no' => true })
      end

      # Get all UPnP port mappings.
      #
      # UPnP mappings are automatically created by devices on the network.
      # These are read-only and managed by the devices themselves.
      #
      # == Keenetic API Request
      #   GET /rci/show/upnp/redirect
      #
      # == Response Fields
      #   - protocol: "tcp" or "udp"
      #   - interface: WAN interface
      #   - port: External port
      #   - to_host: Internal host IP
      #   - to_port: Internal port
      #   - description: Mapping description (from device)
      #
      # @return [Array<Hash>] List of normalized UPnP mappings
      # @example
      #   mappings = client.nat.upnp_mappings
      #   # => [{ protocol: "tcp", port: 51234, to_host: "192.168.1.50", ... }]
      #
      def upnp_mappings
        response = get('/rci/show/upnp/redirect')
        normalize_upnp_mappings(response)
      end

      private

      def normalize_upnp_mappings(response)
        return [] unless response.is_a?(Array)

        response.map { |mapping| normalize_upnp_mapping(mapping) }.compact
      end

      def normalize_upnp_mapping(data)
        return nil unless data.is_a?(Hash)

        {
          protocol: data['protocol'],
          interface: data['interface'],
          port: data['port'],
          to_host: data['to-host'],
          to_port: data['to-port'],
          description: data['description']
        }
      end

      def normalize_rules(response)
        return [] unless response.is_a?(Array)

        response.map { |rule| normalize_rule(rule) }.compact
      end

      def normalize_rule(data)
        return nil unless data.is_a?(Hash)

        {
          index: data['index'],
          description: data['description'],
          protocol: data['protocol'],
          interface: data['interface'],
          port: data['port'],
          end_port: data['end-port'],
          to_host: data['to-host'],
          to_port: data['to-port'],
          enabled: normalize_boolean(data['enabled'])
        }
      end
    end
  end
end
