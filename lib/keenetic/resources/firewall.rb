module Keenetic
  module Resources
    # Firewall resource for managing firewall policies and access lists.
    #
    # == API Endpoints Used
    #
    # === Reading Firewall Policies
    #   GET /rci/show/ip/policy
    #   Returns: Firewall policy configuration
    #
    # === Reading Access Lists
    #   GET /rci/show/access-list
    #   Returns: Access control lists
    #
    # === Adding Firewall Rule
    #   POST /rci/ip/policy
    #   Body: Rule configuration
    #
    class Firewall < Base
      # Get firewall policies.
      #
      # == Keenetic API Request
      #   GET /rci/show/ip/policy
      #
      # @return [Hash] Firewall policy configuration
      # @example
      #   policies = client.firewall.policies
      #
      def policies
        response = get('/rci/show/ip/policy')
        normalize_response(response)
      end

      # Get access control lists.
      #
      # == Keenetic API Request
      #   GET /rci/show/access-list
      #
      # @return [Hash] Access lists configuration
      # @example
      #   lists = client.firewall.access_lists
      #
      def access_lists
        response = get('/rci/show/access-list')
        normalize_response(response)
      end

      # Add a firewall rule.
      #
      # == Keenetic API Request
      #   POST /rci/ip/policy
      #
      # @param params [Hash] Rule configuration
      # @return [Hash, nil] API response
      #
      # @example Add a basic rule
      #   client.firewall.add_rule(
      #     action: 'permit',
      #     protocol: 'tcp',
      #     src: '192.168.1.0/24',
      #     dst_port: 80
      #   )
      #
      def add_rule(**params)
        post('/rci/ip/policy', normalize_params(params))
      end

      # Delete a firewall rule.
      #
      # == Keenetic API Request
      #   POST /rci/ip/policy
      #   Body: { index, no: true }
      #
      # @param index [Integer] Rule index to delete
      # @return [Hash, nil] API response
      #
      # @example
      #   client.firewall.delete_rule(index: 1)
      #
      def delete_rule(index:)
        post('/rci/ip/policy', { 'index' => index, 'no' => true })
      end

      private

      def normalize_response(response)
        return {} unless response.is_a?(Hash)

        deep_normalize_keys(response)
      end

      def normalize_params(params)
        result = {}
        params.each do |key, value|
          # Convert snake_case to kebab-case for API
          api_key = key.to_s.tr('_', '-')
          result[api_key] = value
        end
        result
      end
    end
  end
end
