module Keenetic
  module Resources
    # VPN resource for managing VPN server and monitoring connections.
    #
    # == API Endpoints Used
    #
    # === Reading VPN Server Status
    #   GET /rci/show/vpn-server
    #   Returns: VPN server configuration and status
    #
    # === Reading VPN Clients
    #   GET /rci/show/vpn-server/clients
    #   Returns: Array of connected VPN clients
    #
    # === Reading IPsec Status
    #   GET /rci/show/crypto/ipsec/sa
    #   Returns: IPsec security associations
    #
    # === Configuring VPN Server
    #   POST /rci/vpn-server
    #   Body: { type, enabled, pool-start, pool-end, ... }
    #
    class Vpn < Base
      # Get VPN server status and configuration.
      #
      # == Keenetic API Request
      #   GET /rci/show/vpn-server
      #
      # == Response Fields
      #   - type: VPN server type (pptp, l2tp, sstp, etc.)
      #   - enabled: Whether server is enabled
      #   - running: Whether server is currently running
      #   - pool_start: Start of IP pool for clients
      #   - pool_end: End of IP pool for clients
      #   - interface: VPN interface name
      #
      # @return [Hash] VPN server status
      # @example
      #   status = client.vpn.status
      #   # => { type: "l2tp", enabled: true, running: true, ... }
      #
      def status
        response = get('/rci/show/vpn-server')
        normalize_status(response)
      end

      # Get connected VPN clients.
      #
      # == Keenetic API Request
      #   GET /rci/show/vpn-server/clients
      #
      # == Response Fields (per client)
      #   - name: Client username
      #   - ip: Assigned IP address
      #   - uptime: Connection duration in seconds
      #   - rxbytes: Bytes received
      #   - txbytes: Bytes transmitted
      #
      # @return [Array<Hash>] List of connected VPN clients
      # @example
      #   clients = client.vpn.clients
      #   # => [{ name: "user1", ip: "192.168.1.200", uptime: 3600, ... }]
      #
      def clients
        response = get('/rci/show/vpn-server/clients')
        normalize_clients(response)
      end

      # Get IPsec security associations status.
      #
      # == Keenetic API Request
      #   GET /rci/show/crypto/ipsec/sa
      #
      # == Response Fields
      #   - established: Number of established SAs
      #   - sa: Array of security associations
      #
      # @return [Hash] IPsec status with security associations
      # @example
      #   ipsec = client.vpn.ipsec_status
      #   # => { established: 2, sa: [...] }
      #
      def ipsec_status
        response = get('/rci/show/crypto/ipsec/sa')
        normalize_ipsec(response)
      end

      # Configure VPN server.
      #
      # == Keenetic API Request
      #   POST /rci/vpn-server
      #   Body: { type, enabled, pool-start, pool-end, ... }
      #
      # @param type [String] VPN type: "pptp", "l2tp", "sstp"
      # @param enabled [Boolean] Enable or disable the server
      # @param pool_start [String, nil] Start of client IP pool
      # @param pool_end [String, nil] End of client IP pool
      # @param mppe [String, nil] MPPE encryption: "require", "prefer", "none"
      # @return [Hash, Array, nil] API response
      #
      # @example Enable L2TP server
      #   client.vpn.configure(
      #     type: 'l2tp',
      #     enabled: true,
      #     pool_start: '192.168.1.200',
      #     pool_end: '192.168.1.210'
      #   )
      #
      # @example Disable VPN server
      #   client.vpn.configure(type: 'pptp', enabled: false)
      #
      def configure(type:, enabled:, pool_start: nil, pool_end: nil, mppe: nil)
        params = {
          'type' => type,
          'enabled' => enabled
        }
        params['pool-start'] = pool_start if pool_start
        params['pool-end'] = pool_end if pool_end
        params['mppe'] = mppe if mppe

        post('/rci/vpn-server', params)
      end

      private

      def normalize_status(response)
        return {} unless response.is_a?(Hash)

        result = deep_normalize_keys(response)
        normalize_booleans(result, %i[enabled running])
        result
      end

      def normalize_clients(response)
        return [] unless response.is_a?(Array)

        response.map { |client_data| normalize_client(client_data) }.compact
      end

      def normalize_client(data)
        return nil unless data.is_a?(Hash)

        deep_normalize_keys(data)
      end

      def normalize_ipsec(response)
        return {} unless response.is_a?(Hash)

        deep_normalize_keys(response)
      end
    end
  end
end
