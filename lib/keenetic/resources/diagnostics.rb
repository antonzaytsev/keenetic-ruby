module Keenetic
  module Resources
    # Diagnostics resource for network troubleshooting tools.
    #
    # == API Endpoints Used
    #
    # === Ping
    #   POST /rci/tools/ping
    #   Body: { host, count }
    #
    # === Traceroute
    #   POST /rci/tools/traceroute
    #   Body: { host }
    #
    # === DNS Lookup
    #   POST /rci/tools/nslookup
    #   Body: { host }
    #
    class Diagnostics < Base
      # Ping a host from the router.
      #
      # == Keenetic API Request
      #   POST /rci/tools/ping
      #   Body: { "host": "8.8.8.8", "count": 4 }
      #
      # @param host [String] Hostname or IP address to ping
      # @param count [Integer] Number of ping packets (default: 4)
      # @return [Hash] Ping results
      #
      # @example Ping Google DNS
      #   result = client.diagnostics.ping('8.8.8.8')
      #   # => { host: "8.8.8.8", transmitted: 4, received: 4, loss: 0, ... }
      #
      # @example Ping with custom count
      #   result = client.diagnostics.ping('google.com', count: 10)
      #
      def ping(host, count: 4)
        response = post('/rci/tools/ping', { 'host' => host, 'count' => count })
        normalize_ping_result(response)
      end

      # Trace route to a host from the router.
      #
      # == Keenetic API Request
      #   POST /rci/tools/traceroute
      #   Body: { "host": "google.com" }
      #
      # @param host [String] Hostname or IP address to trace
      # @return [Hash] Traceroute results with hops
      #
      # @example Trace route to Google
      #   result = client.diagnostics.traceroute('google.com')
      #   # => { host: "google.com", hops: [{ hop: 1, ip: "192.168.1.1", time: 1 }, ...] }
      #
      def traceroute(host)
        response = post('/rci/tools/traceroute', { 'host' => host })
        normalize_traceroute_result(response)
      end

      # Perform DNS lookup from the router.
      #
      # == Keenetic API Request
      #   POST /rci/tools/nslookup
      #   Body: { "host": "google.com" }
      #
      # @param host [String] Hostname to resolve
      # @return [Hash] DNS lookup results
      #
      # @example Lookup Google
      #   result = client.diagnostics.nslookup('google.com')
      #   # => { host: "google.com", addresses: ["142.250.185.46", ...], ... }
      #
      def nslookup(host)
        response = post('/rci/tools/nslookup', { 'host' => host })
        normalize_nslookup_result(response)
      end

      # Alias for nslookup
      alias dns_lookup nslookup

      private

      def normalize_ping_result(response)
        return {} unless response.is_a?(Hash)

        deep_normalize_keys(response)
      end

      def normalize_traceroute_result(response)
        return {} unless response.is_a?(Hash)

        deep_normalize_keys(response)
      end

      def normalize_nslookup_result(response)
        return {} unless response.is_a?(Hash)

        deep_normalize_keys(response)
      end
    end
  end
end
