module Keenetic
  module Resources
    # Manages hotspot hosts and IP policies.
    #
    # == API Endpoints Used
    #
    # === Reading Policies
    #   POST /rci/ (batch format)
    #   Body: [{"show": {"sc": {"ip": {"policy": {}}}}}]
    #   Returns: All IP policies from configuration
    #
    # === Reading Hosts
    #   POST /rci/ (batch format)
    #   Body: [
    #     {"show": {"sc": {"ip": {"hotspot": {"host": {}}}}}},
    #     {"show": {"ip": {"hotspot": {}}}}
    #   ]
    #   Returns: Configuration hosts and runtime hosts
    #
    # === Setting Host Policy
    #   POST /rci/ (batch format)
    #   Body: [
    #     {"webhelp": {"event": {"push": {"data": "..."}}}},
    #     {"ip": {"hotspot": {"host": {"mac": "...", "permit": true, "policy": "..."}}}},
    #     {"system": {"configuration": {"save": {}}}}
    #   ]
    #
    class Hotspot < Base
      # Get all IP policies.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch format)
      #   Body: [{"show": {"sc": {"ip": {"policy": {}}}}}]
      #
      # == Response Structure from API
      #   [
      #     {
      #       "id": "Policy0",
      #       "description": "VPN Policy",
      #       "global": false,
      #       "interface": [
      #         { "name": "Wireguard0", "priority": 100 }
      #       ]
      #     }
      #   ]
      #
      # @return [Array<Hash>] List of normalized policy hashes
      # @example
      #   policies = client.hotspot.policies
      #   # => [{ id: "Policy0", description: "VPN Policy", global: false, interfaces: [...] }]
      #
      def policies
        response = client.batch([{ 'show' => { 'sc' => { 'ip' => { 'policy' => {} } } } }])
        policies_data = extract_policies_from_response(response)
        normalize_policies(policies_data)
      end

      # Get all registered hosts with their policies.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch format)
      #   Body: [
      #     {"show": {"sc": {"ip": {"hotspot": {"host": {}}}}}},
      #     {"show": {"ip": {"hotspot": {}}}}
      #   ]
      #
      # Returns merged data from configuration (static settings) and runtime (current status).
      #
      # @return [Array<Hash>] List of normalized host hashes
      # @example
      #   hosts = client.hotspot.hosts
      #   # => [{ mac: "AA:BB:CC:DD:EE:FF", name: "My Device", policy: "Policy0", permit: true, ... }]
      #
      def hosts
        response = client.batch([
          { 'show' => { 'sc' => { 'ip' => { 'hotspot' => { 'host' => {} } } } } },
          { 'show' => { 'ip' => { 'hotspot' => {} } } }
        ])

        config_hosts = extract_config_hosts(response)
        runtime_hosts = extract_runtime_hosts(response)

        merge_hosts(config_hosts, runtime_hosts)
      end

      # Set or remove policy for a host.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch format)
      #   Body: [
      #     {"webhelp": {"event": {"push": {"data": "{\"type\":\"configuration_change\",\"value\":{\"url\":\"/policies/policy-consumers\"}}"}}}},
      #     {"ip": {"hotspot": {"host": {"mac": "...", "permit": true, "policy": "..."}}}},
      #     {"system": {"configuration": {"save": {}}}}
      #   ]
      #
      # @param mac [String] Client MAC address (required)
      # @param policy [String, nil] Policy name (e.g., "Policy0"), or nil to remove policy
      # @param permit [Boolean] Whether to permit the host (default: true)
      # @return [Array<Hash>] API response
      #
      # @example Assign policy to host
      #   client.hotspot.set_host_policy(mac: "AA:BB:CC:DD:EE:FF", policy: "Policy0")
      #
      # @example Remove policy from host
      #   client.hotspot.set_host_policy(mac: "AA:BB:CC:DD:EE:FF", policy: nil)
      #
      # @example Assign policy with deny access
      #   client.hotspot.set_host_policy(mac: "AA:BB:CC:DD:EE:FF", policy: "Policy0", permit: false)
      #
      def set_host_policy(mac:, policy:, permit: true)
        raise ArgumentError, 'MAC address is required' if mac.nil? || mac.to_s.strip.empty?

        normalized_mac = mac.downcase

        host_params = {
          'mac' => normalized_mac,
          'permit' => permit
        }

        if policy.nil? || policy.to_s.strip.empty?
          # Remove policy assignment
          host_params['policy'] = { 'no' => true }
        else
          host_params['policy'] = policy
        end

        commands = [
          webhelp_event,
          { 'ip' => { 'hotspot' => { 'host' => host_params } } },
          save_config_command
        ]

        client.batch(commands)
      end

      # Find a specific policy by ID.
      #
      # @param id [String] Policy ID (e.g., "Policy0")
      # @return [Hash, nil] Policy data or nil if not found
      # @example
      #   policy = client.hotspot.find_policy(id: "Policy0")
      #   # => { id: "Policy0", description: "VPN Policy", ... }
      #
      def find_policy(id:)
        policies.find { |p| p[:id] == id }
      end

      # Find a specific host by MAC address.
      #
      # @param mac [String] MAC address (case-insensitive)
      # @return [Hash, nil] Host data or nil if not found
      # @example
      #   host = client.hotspot.find_host(mac: "AA:BB:CC:DD:EE:FF")
      #   # => { mac: "AA:BB:CC:DD:EE:FF", name: "My Device", policy: "Policy0", ... }
      #
      def find_host(mac:)
        hosts.find { |h| h[:mac]&.downcase == mac.downcase }
      end

      private

      def extract_policies_from_response(response)
        return [] unless response.is_a?(Array) && response.first.is_a?(Hash)

        response.dig(0, 'show', 'sc', 'ip', 'policy') || []
      end

      def extract_config_hosts(response)
        return [] unless response.is_a?(Array) && response[0].is_a?(Hash)

        hosts = response.dig(0, 'show', 'sc', 'ip', 'hotspot', 'host') || []
        hosts.is_a?(Array) ? hosts : [hosts]
      end

      def extract_runtime_hosts(response)
        return [] unless response.is_a?(Array) && response[1].is_a?(Hash)

        hosts = response.dig(1, 'show', 'ip', 'hotspot', 'host') || []
        hosts.is_a?(Array) ? hosts : [hosts]
      end

      def normalize_policies(policies_data)
        return [] unless policies_data.is_a?(Array)

        policies_data.map { |policy| normalize_policy(policy) }.compact
      end

      def normalize_policy(data)
        return nil unless data.is_a?(Hash)

        interfaces = data['interface'] || []
        interfaces = [interfaces] unless interfaces.is_a?(Array)

        {
          id: data['id'],
          description: data['description'],
          global: normalize_boolean(data['global']),
          interfaces: interfaces.map { |iface| normalize_policy_interface(iface) }.compact
        }
      end

      def normalize_policy_interface(data)
        return nil unless data.is_a?(Hash)

        {
          name: data['name'],
          priority: data['priority']
        }
      end

      def merge_hosts(config_hosts, runtime_hosts)
        # Create lookup from runtime hosts by MAC
        runtime_by_mac = runtime_hosts.each_with_object({}) do |host, lookup|
          next unless host.is_a?(Hash) && host['mac']

          lookup[host['mac'].upcase] = host
        end

        # Process config hosts and merge with runtime data
        all_hosts = config_hosts.map do |config_host|
          next unless config_host.is_a?(Hash) && config_host['mac']

          mac = config_host['mac'].upcase
          runtime_host = runtime_by_mac.delete(mac) || {}
          normalize_host(config_host, runtime_host)
        end.compact

        # Add any remaining runtime-only hosts
        runtime_by_mac.values.each do |runtime_host|
          all_hosts << normalize_host({}, runtime_host)
        end

        all_hosts
      end

      def normalize_host(config_data, runtime_data)
        config_data ||= {}
        runtime_data ||= {}

        mac = config_data['mac'] || runtime_data['mac']
        return nil unless mac

        {
          mac: mac.upcase,
          name: config_data['name'] || runtime_data['name'] || runtime_data['hostname'],
          hostname: runtime_data['hostname'],
          ip: runtime_data['ip'],
          interface: runtime_data['interface'],
          via: runtime_data['via'],
          policy: config_data['policy'],
          permit: normalize_boolean(config_data['permit']),
          deny: normalize_boolean(config_data['deny']),
          schedule: config_data['schedule'],
          active: normalize_boolean(runtime_data['active']),
          registered: normalize_boolean(runtime_data['registered']),
          access: runtime_data['access'],
          rxbytes: runtime_data['rxbytes'],
          txbytes: runtime_data['txbytes'],
          uptime: runtime_data['uptime'],
          first_seen: runtime_data['first-seen'],
          last_seen: runtime_data['last-seen']
        }
      end

      def webhelp_event
        {
          'webhelp' => {
            'event' => {
              'push' => {
                'data' => '{"type":"configuration_change","value":{"url":"/policies/policy-consumers"}}'
              }
            }
          }
        }
      end

      def save_config_command
        { 'system' => { 'configuration' => { 'save' => {} } } }
      end
    end
  end
end
