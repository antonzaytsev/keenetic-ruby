module Keenetic
  module Resources
    # Dynamic DNS resource for managing KeenDNS and third-party DDNS.
    #
    # == API Endpoints Used
    #
    # === KeenDNS Status
    #   GET /rci/show/rc/ip/http/dyndns
    #
    # === Configure KeenDNS
    #   POST /rci/ip/http/dyndns
    #
    # === Third-Party DDNS
    #   GET /rci/show/dyndns
    #
    class Dyndns < Base
      # Get KeenDNS status.
      #
      # @return [Hash] KeenDNS configuration and status
      # @example
      #   status = client.dyndns.keendns_status
      #
      def keendns_status
        response = get('/rci/show/rc/ip/http/dyndns')
        normalize_response(response)
      end

      # Configure KeenDNS.
      #
      # @param params [Hash] KeenDNS configuration parameters
      # @return [Hash, nil] API response
      # @example
      #   client.dyndns.configure_keendns(enabled: true, domain: 'myrouter')
      #
      def configure_keendns(**params)
        post('/rci/ip/http/dyndns', normalize_params(params))
      end

      # Get third-party DDNS providers status.
      #
      # @return [Hash] Third-party DDNS configuration
      # @example
      #   ddns = client.dyndns.third_party
      #
      def third_party
        response = get('/rci/show/dyndns')
        normalize_response(response)
      end

      # Alias for third_party
      alias providers third_party

      private

      def normalize_response(response)
        return {} unless response.is_a?(Hash)

        deep_normalize_keys(response)
      end

      def normalize_params(params)
        result = {}
        params.each do |key, value|
          api_key = key.to_s.tr('_', '-')
          result[api_key] = value
        end
        result
      end
    end
  end
end
