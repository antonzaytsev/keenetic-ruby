module Keenetic
  module Resources
    # DNS-based routes resource for managing FQDN domain groups and their routing rules.
    #
    # DNS-based routing lets you route traffic for a set of domain names through a
    # specific interface. The router resolves each domain and automatically installs
    # floating static routes for the resolved IPs.
    #
    # Two related concepts are managed here:
    #
    # 1. **FQDN Domain Groups** (`object-group fqdn`) — named lists of domains.
    # 2. **DNS-Proxy Routes** (`dns-proxy route`) — maps a domain group to an interface.
    #
    # == API Endpoints Used
    #
    # === Reading FQDN Domain Groups
    #   POST /rci/ (batch)
    #   Body: [{"show":{"sc":{"object-group":{"fqdn":{}}}}}]
    #   Returns: Hash keyed by group name
    #
    # === Creating FQDN Domain Group
    #   POST /rci/ (batch)
    #   Body: [
    #     webhelp_event,
    #     {"object-group":{"fqdn":{"<name>":{"description":"...","include":[{"address":"..."}]}}}},
    #     save_config
    #   ]
    #
    # === Deleting FQDN Domain Group
    #   POST /rci/ (batch)
    #   Body: [
    #     webhelp_event,
    #     {"object-group":{"fqdn":{"<name>":{"no":true}}}},
    #     save_config
    #   ]
    #
    # === Reading DNS-Based Routes
    #   POST /rci/ (batch)
    #   Body: [{"show":{"sc":{"dns-proxy":{"route":{}}}}}]
    #   Returns: Array of route entries
    #
    # === Creating DNS-Based Route
    #   POST /rci/ (batch)
    #   Body: [
    #     webhelp_event,
    #     {"dns-proxy":{"route":{"group":"...","interface":"...","comment":"..."}}},
    #     save_config
    #   ]
    #
    # === Deleting DNS-Based Route
    #   POST /rci/ (batch)
    #   Body: [
    #     webhelp_event,
    #     {"dns-proxy":{"route":{"no":true,"index":"..."}}},
    #     save_config
    #   ]
    #
    class DnsRoutes < Base
      # Get all FQDN domain groups.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch)
      #   Body: [{"show":{"sc":{"object-group":{"fqdn":{}}}}}]
      #
      # == Response Structure from API
      #   {
      #     "domain-list0": {
      #       "description": "youtube.com",
      #       "include": [{"address": "googlevideo.com"}, {"address": "youtube.com"}]
      #     }
      #   }
      #
      # @return [Array<Hash>] List of domain groups, each with :name, :description, :domains
      # @example
      #   groups = client.dns_routes.domain_groups
      #   # => [{ name: "domain-list0", description: "youtube.com", domains: ["googlevideo.com", "youtube.com"] }]
      #
      def domain_groups
        response = client.batch([{ 'show' => { 'sc' => { 'object-group' => { 'fqdn' => {} } } } }])
        fqdn_data = response.dig(0, 'show', 'sc', 'object-group', 'fqdn') || {}
        normalize_domain_groups(fqdn_data)
      end

      # Find a single FQDN domain group by name.
      #
      # @param name [String] Group name (e.g., "domain-list0")
      # @return [Hash, nil] Domain group or nil if not found
      # @example
      #   group = client.dns_routes.find_domain_group(name: "domain-list0")
      #   # => { name: "domain-list0", description: "youtube.com", domains: [...] }
      #
      def find_domain_group(name:)
        domain_groups.find { |g| g[:name] == name }
      end

      # Create an FQDN domain group.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch)
      #   Body: [webhelp_event, {"object-group":{"fqdn":{"<name>":{"description":"...","include":[...]}}}}, save]
      #
      # @param name [String] Group identifier (e.g., "domain-list0")
      # @param description [String] Human-readable label
      # @param domains [Array<String>] List of domain names to include
      # @return [Array<Hash>] API response
      # @raise [ArgumentError] if name, description, or domains are missing/empty
      # @example
      #   client.dns_routes.create_domain_group(
      #     name: "domain-list0",
      #     description: "YouTube",
      #     domains: ["youtube.com", "googlevideo.com"]
      #   )
      #
      def create_domain_group(name:, description:, domains:)
        raise ArgumentError, 'Name is required' if name.nil? || name.to_s.strip.empty?
        raise ArgumentError, 'Description is required' if description.nil? || description.to_s.strip.empty?
        raise ArgumentError, 'Domains cannot be empty' if domains.nil? || domains.empty?

        include_list = domains.map { |d| { 'address' => d.to_s } }

        commands = [
          webhelp_event,
          { 'object-group' => { 'fqdn' => { name.to_s => { 'description' => description.to_s, 'include' => include_list } } } },
          save_config_command
        ]

        client.batch(commands)
      end

      # Delete an FQDN domain group.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch)
      #   Body: [webhelp_event, {"object-group":{"fqdn":{"<name>":{"no":true}}}}, save]
      #
      # @param name [String] Group name to delete
      # @return [Array<Hash>] API response
      # @raise [ArgumentError] if name is missing
      # @example
      #   client.dns_routes.delete_domain_group(name: "domain-list0")
      #
      def delete_domain_group(name:)
        raise ArgumentError, 'Name is required' if name.nil? || name.to_s.strip.empty?

        commands = [
          webhelp_event,
          { 'object-group' => { 'fqdn' => { name.to_s => { 'no' => true } } } },
          save_config_command
        ]

        client.batch(commands)
      end

      # Get all DNS-based routes.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch)
      #   Body: [{"show":{"sc":{"dns-proxy":{"route":{}}}}}]
      #
      # == Response Structure from API
      #   [
      #     {
      #       "group": "domain-list0",
      #       "interface": "Wireguard2",
      #       "auto": true,
      #       "index": "c52bba355a2830fdf55ccb3748a879df",
      #       "comment": ""
      #     }
      #   ]
      #
      # @return [Array<Hash>] List of DNS-based routes with :group, :interface, :auto, :index, :comment
      # @example
      #   routes = client.dns_routes.routes
      #   # => [{ group: "domain-list0", interface: "Wireguard2", auto: true, index: "c52b...", comment: "" }]
      #
      def routes
        response = client.batch([{ 'show' => { 'sc' => { 'dns-proxy' => { 'route' => {} } } } }])
        routes_data = response.dig(0, 'show', 'sc', 'dns-proxy', 'route') || []
        normalize_routes(routes_data)
      end

      # Find a DNS-based route by FQDN group name.
      #
      # @param group [String] FQDN group name
      # @return [Hash, nil] Route or nil if not found
      # @example
      #   route = client.dns_routes.find_route(group: "domain-list0")
      #   # => { group: "domain-list0", interface: "Wireguard2", index: "...", ... }
      #
      def find_route(group:)
        routes.find { |r| r[:group] == group }
      end

      # Create a DNS-based route mapping a domain group to an interface.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch)
      #   Body: [webhelp_event, {"dns-proxy":{"route":{"group":"...","interface":"...","comment":"..."}}}, save]
      #
      # @param group [String] FQDN group name (e.g., "domain-list0")
      # @param interface [String] Target interface (e.g., "Wireguard0")
      # @param comment [String] Optional description (default: "")
      # @return [Array<Hash>] API response
      # @raise [ArgumentError] if group or interface is missing
      # @example
      #   client.dns_routes.add_route(group: "domain-list0", interface: "Wireguard0")
      #
      def add_route(group:, interface:, comment: '')
        raise ArgumentError, 'Group is required' if group.nil? || group.to_s.strip.empty?
        raise ArgumentError, 'Interface is required' if interface.nil? || interface.to_s.strip.empty?

        commands = [
          webhelp_event,
          { 'dns-proxy' => { 'route' => { 'group' => group.to_s, 'interface' => interface.to_s, 'comment' => comment.to_s } } },
          save_config_command
        ]

        client.batch(commands)
      end

      # Delete a DNS-based route by its index.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch)
      #   Body: [webhelp_event, {"dns-proxy":{"route":{"no":true,"index":"..."}}}, save]
      #
      # @param index [String] Route index (MD5 hash from routes list)
      # @return [Array<Hash>] API response
      # @raise [ArgumentError] if index is missing
      # @example
      #   client.dns_routes.delete_route(index: "c52bba355a2830fdf55ccb3748a879df")
      #
      def delete_route(index:)
        raise ArgumentError, 'Index is required' if index.nil? || index.to_s.strip.empty?

        commands = [
          webhelp_event,
          { 'dns-proxy' => { 'route' => { 'no' => true, 'index' => index.to_s } } },
          save_config_command
        ]

        client.batch(commands)
      end

      private

      def normalize_domain_groups(fqdn_data)
        return [] unless fqdn_data.is_a?(Hash)

        fqdn_data.map do |name, data|
          next nil unless data.is_a?(Hash)

          domains = Array(data['include']).map { |entry| entry['address'] }.compact

          {
            name: name,
            description: data['description'],
            domains: domains
          }
        end.compact
      end

      def normalize_routes(routes_data)
        return [] unless routes_data.is_a?(Array)

        routes_data.map { |r| normalize_route(r) }.compact
      end

      def normalize_route(data)
        return nil unless data.is_a?(Hash)

        {
          group: data['group'],
          interface: data['interface'],
          auto: normalize_boolean(data['auto']),
          index: data['index'],
          comment: data['comment']
        }
      end

      def webhelp_event
        {
          'webhelp' => {
            'event' => {
              'push' => {
                'data' => '{"type":"configuration_change","value":{"url":"/staticRoutes/dns"}}'
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
