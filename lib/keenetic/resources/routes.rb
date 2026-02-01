module Keenetic
  module Resources
    # Manages static routes configuration on the router.
    #
    # == API Endpoints Used
    #
    # === Reading Static Routes
    #   POST /rci/ (batch format)
    #   Body: [{"show": {"sc": {"ip": {"route": {}}}}}]
    #   Returns: Static routes from router configuration
    #
    # === Adding Static Routes
    #   POST /rci/ (batch format)
    #   Body: [
    #     {"webhelp": {"event": {"push": {"data": "..."}}}},
    #     {"ip": {"route": {...}}},
    #     {"system": {"configuration": {"save": {}}}}
    #   ]
    #
    # === Deleting Static Routes
    #   POST /rci/ (batch format)
    #   Body: [
    #     {"webhelp": {"event": {"push": {"data": "..."}}}},
    #     {"ip": {"route": {"no": true, ...}}},
    #     {"system": {"configuration": {"save": {}}}}
    #   ]
    #
    # == CIDR Support
    # The gem automatically converts CIDR notation to subnet masks:
    #   host: "10.0.0.0/24" -> network: "10.0.0.0", mask: "255.255.255.0"
    #   host: "1.2.3.4/32"  -> host: "1.2.3.4"
    #
    class Routes < Base
      # CIDR prefix to subnet mask mapping
      CIDR_TO_MASK = {
        8  => '255.0.0.0',
        9  => '255.128.0.0',
        10 => '255.192.0.0',
        11 => '255.224.0.0',
        12 => '255.240.0.0',
        13 => '255.248.0.0',
        14 => '255.252.0.0',
        15 => '255.254.0.0',
        16 => '255.255.0.0',
        17 => '255.255.128.0',
        18 => '255.255.192.0',
        19 => '255.255.224.0',
        20 => '255.255.240.0',
        21 => '255.255.248.0',
        22 => '255.255.252.0',
        23 => '255.255.254.0',
        24 => '255.255.255.0',
        25 => '255.255.255.128',
        26 => '255.255.255.192',
        27 => '255.255.255.224',
        28 => '255.255.255.240',
        29 => '255.255.255.248',
        30 => '255.255.255.252',
        31 => '255.255.255.254',
        32 => '255.255.255.255'
      }.freeze

      # Get all static routes from router configuration.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch format)
      #   Body: [{"show": {"sc": {"ip": {"route": {}}}}}]
      #
      # == Response Structure from API
      #   [
      #     {
      #       "network": "10.0.0.0",
      #       "mask": "255.255.255.0",
      #       "interface": "Wireguard0",
      #       "gateway": "",
      #       "auto": true,
      #       "reject": false,
      #       "comment": "VPN route"
      #     }
      #   ]
      #
      # @return [Array<Hash>] List of normalized static route hashes
      # @example
      #   routes = client.routes.all
      #   # => [{ network: "10.0.0.0", mask: "255.255.255.0", interface: "Wireguard0", ... }]
      #
      def all
        response = client.batch([{ 'show' => { 'sc' => { 'ip' => { 'route' => {} } } } }])
        routes_data = extract_routes_from_response(response)
        normalize_routes(routes_data)
      end

      # Add a single static route.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch format)
      #   Body: [
      #     {"webhelp": {"event": {"push": {"data": "{\"type\":\"configuration_change\",\"value\":{\"url\":\"/staticRoutes\"}}"}}}},
      #     {"ip": {"route": {"host|network": "...", "mask": "...", "interface": "...", ...}}},
      #     {"system": {"configuration": {"save": {}}}}
      #   ]
      #
      # @param host [String, nil] Single host IP (e.g., "1.2.3.4" or "1.2.3.4/32"), mutually exclusive with network/mask
      # @param network [String, nil] Network address (e.g., "10.0.0.0" or "10.0.0.0/24")
      # @param mask [String, nil] Subnet mask (e.g., "255.255.255.0"), required with network unless CIDR notation used
      # @param interface [String] Interface name (required, e.g., "Wireguard0")
      # @param comment [String] Route description (required)
      # @param gateway [String] Gateway address (optional, default "")
      # @param auto [Boolean] Auto-enable route (optional, default true)
      # @param reject [Boolean] Reject route (optional, default false)
      # @return [Array<Hash>] API response
      # @raise [ArgumentError] if required parameters are missing or invalid
      #
      # @example Add host route
      #   client.routes.add(host: "1.2.3.4", interface: "Wireguard0", comment: "VPN host")
      #
      # @example Add network route with CIDR
      #   client.routes.add(network: "10.0.0.0/24", interface: "Wireguard0", comment: "VPN network")
      #
      # @example Add network route with explicit mask
      #   client.routes.add(network: "10.0.0.0", mask: "255.255.255.0", interface: "Wireguard0", comment: "VPN network")
      #
      def add(host: nil, network: nil, mask: nil, interface:, comment:, gateway: '', auto: true, reject: false)
        route_params = build_route_params(
          host: host,
          network: network,
          mask: mask,
          interface: interface,
          comment: comment,
          gateway: gateway,
          auto: auto,
          reject: reject
        )

        commands = [
          webhelp_event,
          { 'ip' => { 'route' => route_params } },
          save_config_command
        ]

        response = client.batch(commands)
        validate_route_response(response)
        response
      end

      # Add multiple static routes in a single request.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch format)
      #   Body: [
      #     {"webhelp": {"event": {"push": {"data": "..."}}}},
      #     {"ip": {"route": {...}}},
      #     {"ip": {"route": {...}}},
      #     ...
      #     {"system": {"configuration": {"save": {}}}}
      #   ]
      #
      # @param routes [Array<Hash>] Array of route parameter hashes (same format as #add)
      # @return [Array<Hash>] API response
      # @raise [ArgumentError] if routes is empty or any route has invalid parameters
      #
      # @example Add multiple routes
      #   client.routes.add_batch([
      #     { host: "1.2.3.4", interface: "Wireguard0", comment: "Host 1" },
      #     { network: "10.0.0.0/24", interface: "Wireguard0", comment: "Network 1" }
      #   ])
      #
      def add_batch(routes)
        raise ArgumentError, 'Routes array cannot be empty' if routes.nil? || routes.empty?

        commands = [webhelp_event]

        routes.each do |route|
          route_params = build_route_params(
            host: route[:host],
            network: route[:network],
            mask: route[:mask],
            interface: route[:interface],
            comment: route[:comment],
            gateway: route[:gateway] || '',
            auto: route.fetch(:auto, true),
            reject: route.fetch(:reject, false)
          )
          commands << { 'ip' => { 'route' => route_params } }
        end

        commands << save_config_command

        response = client.batch(commands)
        validate_batch_response(response, routes.size)
        response
      end

      # Delete a single static route.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch format)
      #   Body: [
      #     {"webhelp": {"event": {"push": {"data": "..."}}}},
      #     {"ip": {"route": {"no": true, "host|network": "...", "mask": "..."}}},
      #     {"system": {"configuration": {"save": {}}}}
      #   ]
      #
      # @param host [String, nil] Single host IP (e.g., "1.2.3.4")
      # @param network [String, nil] Network address (e.g., "10.0.0.0")
      # @param mask [String, nil] Subnet mask (e.g., "255.255.255.0")
      # @return [Array<Hash>] API response
      # @raise [ArgumentError] if neither host nor network is provided
      #
      # @example Delete host route
      #   client.routes.delete(host: "1.2.3.4")
      #
      # @example Delete network route with CIDR
      #   client.routes.delete(network: "10.0.0.0/24")
      #
      # @example Delete network route with explicit mask
      #   client.routes.delete(network: "10.0.0.0", mask: "255.255.255.0")
      #
      def delete(host: nil, network: nil, mask: nil)
        route_params = build_delete_params(host: host, network: network, mask: mask)

        commands = [
          webhelp_event,
          { 'ip' => { 'route' => route_params } },
          save_config_command
        ]

        client.batch(commands)
      end

      # Delete multiple static routes in a single request.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch format)
      #   Body: [
      #     {"webhelp": {"event": {"push": {"data": "..."}}}},
      #     {"ip": {"route": {"no": true, ...}}},
      #     {"ip": {"route": {"no": true, ...}}},
      #     ...
      #     {"system": {"configuration": {"save": {}}}}
      #   ]
      #
      # @param routes [Array<Hash>] Array of route identifiers (host or network/mask)
      # @return [Array<Hash>] API response
      # @raise [ArgumentError] if routes is empty
      #
      # @example Delete multiple routes
      #   client.routes.delete_batch([
      #     { host: "1.2.3.4" },
      #     { network: "10.0.0.0/24" }
      #   ])
      #
      def delete_batch(routes)
        raise ArgumentError, 'Routes array cannot be empty' if routes.nil? || routes.empty?

        commands = [webhelp_event]

        routes.each do |route|
          route_params = build_delete_params(
            host: route[:host],
            network: route[:network],
            mask: route[:mask]
          )
          commands << { 'ip' => { 'route' => route_params } }
        end

        commands << save_config_command

        client.batch(commands)
      end

      # Convert CIDR notation to subnet mask.
      #
      # @param cidr [Integer, String] CIDR prefix length (8-32)
      # @return [String] Subnet mask in dotted notation
      # @raise [ArgumentError] if CIDR is invalid
      #
      # @example
      #   Keenetic::Resources::Routes.cidr_to_mask(24)
      #   # => "255.255.255.0"
      #
      def self.cidr_to_mask(cidr)
        prefix = cidr.to_i
        raise ArgumentError, "Invalid CIDR prefix: #{cidr}" unless CIDR_TO_MASK.key?(prefix)

        CIDR_TO_MASK[prefix]
      end

      private

      def extract_routes_from_response(response)
        return [] unless response.is_a?(Array) && response.first.is_a?(Hash)

        response.dig(0, 'show', 'sc', 'ip', 'route') || []
      end

      def normalize_routes(routes_data)
        return [] unless routes_data.is_a?(Array)

        routes_data.map { |route| normalize_route(route) }.compact
      end

      def normalize_route(data)
        return nil unless data.is_a?(Hash)

        {
          network: data['network'],
          mask: data['mask'],
          host: data['host'],
          interface: data['interface'],
          gateway: data['gateway'],
          comment: data['comment'],
          auto: normalize_boolean(data['auto']),
          reject: normalize_boolean(data['reject'])
        }
      end

      def build_route_params(host:, network:, mask:, interface:, comment:, gateway:, auto:, reject:)
        raise ArgumentError, 'Interface is required' if interface.nil? || interface.to_s.strip.empty?
        raise ArgumentError, 'Comment is required' if comment.nil? || comment.to_s.strip.empty?

        params = {}

        if host && !host.to_s.strip.empty?
          parsed = parse_cidr(host)
          if parsed[:cidr] == 32 || parsed[:cidr].nil?
            params['host'] = parsed[:address]
          else
            # If CIDR is not /32, treat as network
            params['network'] = parsed[:address]
            params['mask'] = self.class.cidr_to_mask(parsed[:cidr])
          end
        elsif network && !network.to_s.strip.empty?
          parsed = parse_cidr(network)
          params['network'] = parsed[:address]
          params['mask'] = parsed[:cidr] ? self.class.cidr_to_mask(parsed[:cidr]) : mask
          raise ArgumentError, 'Mask is required for network routes without CIDR notation' if params['mask'].nil?
        else
          raise ArgumentError, 'Either host or network must be provided'
        end

        params['interface'] = interface
        params['comment'] = comment
        params['gateway'] = gateway.to_s
        params['auto'] = auto
        params['reject'] = reject

        params
      end

      def build_delete_params(host:, network:, mask:)
        params = { 'no' => true }

        if host && !host.to_s.strip.empty?
          parsed = parse_cidr(host)
          if parsed[:cidr] == 32 || parsed[:cidr].nil?
            params['host'] = parsed[:address]
          else
            params['network'] = parsed[:address]
            params['mask'] = self.class.cidr_to_mask(parsed[:cidr])
          end
        elsif network && !network.to_s.strip.empty?
          parsed = parse_cidr(network)
          params['network'] = parsed[:address]
          params['mask'] = parsed[:cidr] ? self.class.cidr_to_mask(parsed[:cidr]) : mask
          raise ArgumentError, 'Mask is required for network routes without CIDR notation' if params['mask'].nil?
        else
          raise ArgumentError, 'Either host or network must be provided'
        end

        params
      end

      def parse_cidr(address)
        return { address: address, cidr: nil } unless address.to_s.include?('/')

        parts = address.to_s.split('/')
        { address: parts[0], cidr: parts[1].to_i }
      end

      def webhelp_event
        {
          'webhelp' => {
            'event' => {
              'push' => {
                'data' => '{"type":"configuration_change","value":{"url":"/staticRoutes"}}'
              }
            }
          }
        }
      end

      def save_config_command
        { 'system' => { 'configuration' => { 'save' => {} } } }
      end

      def validate_route_response(response)
        return unless response.is_a?(Array)

        # Response index 1 is the route command response
        route_response = response[1]
        return unless route_response.is_a?(Hash)

        status = route_response.dig('ip', 'route', 'status')
        return unless status.is_a?(Array) && status.first.is_a?(Hash)

        if status.first['status'] == 'error'
          error_msg = status.first['message'] || 'Unknown error'
          raise ApiError.new("Failed to add route: #{error_msg}")
        end
      end

      def validate_batch_response(response, routes_count)
        return unless response.is_a?(Array)

        # Route responses start at index 1 (after webhelp event)
        (1..routes_count).each do |i|
          route_response = response[i]
          next unless route_response.is_a?(Hash)

          status = route_response.dig('ip', 'route', 'status')
          next unless status.is_a?(Array) && status.first.is_a?(Hash)

          if status.first['status'] == 'error'
            error_msg = status.first['message'] || 'Unknown error'
            raise ApiError.new("Failed to add route at index #{i - 1}: #{error_msg}")
          end
        end
      end
    end
  end
end
