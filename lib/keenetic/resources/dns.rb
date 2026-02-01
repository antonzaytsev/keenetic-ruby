module Keenetic
  module Resources
    # DNS resource for managing DNS settings and cache.
    #
    # == API Endpoints Used
    #
    # === Reading DNS Servers
    #   GET /rci/show/ip/name-server
    #   Returns: Configured DNS servers
    #
    # === Reading DNS Cache
    #   GET /rci/show/dns/cache
    #   Returns: DNS cache entries
    #
    # === Reading DNS Proxy Settings
    #   GET /rci/show/dns/proxy
    #   Returns: DNS proxy configuration
    #
    # === Clear DNS Cache
    #   POST /rci/dns/cache/clear
    #   Body: {}
    #
    class Dns < Base
      # Get configured DNS servers.
      #
      # == Keenetic API Request
      #   GET /rci/show/ip/name-server
      #
      # @return [Hash] DNS servers configuration
      # @example
      #   servers = client.dns.servers
      #
      def servers
        response = get('/rci/show/ip/name-server')
        normalize_response(response)
      end

      # Alias for servers
      alias name_servers servers

      # Get DNS cache entries.
      #
      # == Keenetic API Request
      #   GET /rci/show/dns/cache
      #
      # @return [Hash] DNS cache data
      # @example
      #   cache = client.dns.cache
      #
      def cache
        response = get('/rci/show/dns/cache')
        normalize_response(response)
      end

      # Get DNS proxy settings.
      #
      # == Keenetic API Request
      #   GET /rci/show/dns/proxy
      #
      # @return [Hash] DNS proxy configuration
      # @example
      #   proxy = client.dns.proxy
      #
      def proxy
        response = get('/rci/show/dns/proxy')
        normalize_response(response)
      end

      # Alias for proxy
      alias proxy_settings proxy

      # Clear DNS cache.
      #
      # == Keenetic API Request
      #   POST /rci/dns/cache/clear
      #   Body: {}
      #
      # @return [Hash, nil] API response
      # @example
      #   client.dns.clear_cache
      #
      def clear_cache
        post('/rci/dns/cache/clear', {})
      end

      private

      def normalize_response(response)
        return {} unless response.is_a?(Hash)

        deep_normalize_keys(response)
      end
    end
  end
end
