module Keenetic
  module Resources
    # QoS resource for Quality of Service and traffic control.
    #
    # == API Endpoints Used
    #
    # === Traffic Shaper Status
    #   GET /rci/show/ip/traffic-control
    #
    # === IntelliQoS Settings
    #   GET /rci/show/ip/qos
    #
    # === Traffic Statistics by Host
    #   GET /rci/show/ip/hotspot/summary
    #
    class Qos < Base
      # Get traffic shaper status.
      #
      # @return [Hash] Traffic shaper configuration and status
      # @example
      #   shaper = client.qos.traffic_shaper
      #
      def traffic_shaper
        response = get('/rci/show/ip/traffic-control')
        normalize_response(response)
      end

      # Alias for traffic_shaper
      alias shaper traffic_shaper

      # Get IntelliQoS settings.
      #
      # @return [Hash] IntelliQoS configuration
      # @example
      #   qos = client.qos.intelliqos
      #
      def intelliqos
        response = get('/rci/show/ip/qos')
        normalize_response(response)
      end

      # Alias for intelliqos
      alias settings intelliqos

      # Get traffic statistics by host.
      #
      # @return [Array<Hash>] Traffic statistics per host
      # @example
      #   stats = client.qos.traffic_stats
      #
      def traffic_stats
        response = get('/rci/show/ip/hotspot/summary')
        normalize_stats(response)
      end

      # Alias for traffic_stats
      alias host_stats traffic_stats

      private

      def normalize_response(response)
        return {} unless response.is_a?(Hash)

        deep_normalize_keys(response)
      end

      def normalize_stats(response)
        stats_data = case response
                     when Array
                       response
                     when Hash
                       response['host'] || response['hosts'] || response['stat'] || []
                     else
                       []
                     end

        return [] unless stats_data.is_a?(Array)

        stats_data.map { |stat| normalize_stat(stat) }.compact
      end

      def normalize_stat(data)
        return nil unless data.is_a?(Hash)

        deep_normalize_keys(data)
      end
    end
  end
end
