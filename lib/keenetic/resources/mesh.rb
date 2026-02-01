module Keenetic
  module Resources
    # Mesh resource for monitoring mesh Wi-Fi system status.
    #
    # == API Endpoints Used
    #
    # === Reading Mesh Status
    #   GET /rci/show/mws
    #   Returns: Mesh Wi-Fi system status and configuration
    #
    # === Reading Mesh Members
    #   GET /rci/show/mws/member
    #   Returns: Connected mesh nodes/extenders
    #
    class Mesh < Base
      # Get mesh Wi-Fi system status.
      #
      # == Keenetic API Request
      #   GET /rci/show/mws
      #
      # @return [Hash] Mesh system status and configuration
      # @example
      #   status = client.mesh.status
      #   # => { enabled: true, role: "controller", members_count: 2, ... }
      #
      def status
        response = get('/rci/show/mws')
        normalize_status(response)
      end

      # Get connected mesh members (nodes/extenders).
      #
      # == Keenetic API Request
      #   GET /rci/show/mws/member
      #
      # @return [Array<Hash>] List of mesh members
      # @example
      #   members = client.mesh.members
      #   # => [
      #   #   { mac: "AA:BB:CC:DD:EE:FF", name: "Living Room", mode: "extender", ... },
      #   #   ...
      #   # ]
      #
      def members
        response = get('/rci/show/mws/member')
        normalize_members(response)
      end

      private

      def normalize_status(response)
        return {} unless response.is_a?(Hash)

        result = deep_normalize_keys(response)
        normalize_booleans(result, %i[enabled active])
        result
      end

      def normalize_members(response)
        # Response might be array directly or wrapped in an object
        members_data = case response
                       when Array
                         response
                       when Hash
                         response['member'] || response['members'] || []
                       else
                         []
                       end

        return [] unless members_data.is_a?(Array)

        members_data.map { |member| normalize_member(member) }.compact
      end

      def normalize_member(data)
        return nil unless data.is_a?(Hash)

        result = deep_normalize_keys(data)
        normalize_booleans(result, %i[online active connected])
        result
      end
    end
  end
end
