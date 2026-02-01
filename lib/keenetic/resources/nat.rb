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

      private

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
