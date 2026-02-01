module Keenetic
  module Resources
    # IPv6 resource for IPv6 network information.
    #
    # == API Endpoints Used
    #
    # === IPv6 Interfaces
    #   GET /rci/show/ipv6/interface
    #
    # === IPv6 Routes
    #   GET /rci/show/ipv6/route
    #
    # === IPv6 Neighbors
    #   GET /rci/show/ipv6/neighbor
    #
    class Ipv6 < Base
      # Get IPv6 interfaces.
      #
      # @return [Array<Hash>] List of IPv6 interfaces
      # @example
      #   interfaces = client.ipv6.interfaces
      #
      def interfaces
        response = get('/rci/show/ipv6/interface')
        normalize_list(response, 'interface')
      end

      # Get IPv6 routing table.
      #
      # @return [Array<Hash>] List of IPv6 routes
      # @example
      #   routes = client.ipv6.routes
      #
      def routes
        response = get('/rci/show/ipv6/route')
        normalize_list(response, 'route')
      end

      # Get IPv6 neighbor table (NDP cache).
      #
      # @return [Array<Hash>] List of IPv6 neighbors
      # @example
      #   neighbors = client.ipv6.neighbors
      #
      def neighbors
        response = get('/rci/show/ipv6/neighbor')
        normalize_list(response, 'neighbor')
      end

      private

      def normalize_list(response, key)
        data = case response
               when Array
                 response
               when Hash
                 response[key] || response["#{key}s"] || []
               else
                 []
               end

        return [] unless data.is_a?(Array)

        data.map { |item| normalize_item(item) }.compact
      end

      def normalize_item(data)
        return nil unless data.is_a?(Hash)

        deep_normalize_keys(data)
      end
    end
  end
end
