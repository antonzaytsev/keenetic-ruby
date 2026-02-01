module Keenetic
  module Resources
    # Components resource for managing installable router components.
    #
    # == API Endpoints Used
    #
    # === Installed Components
    #   GET /rci/show/components
    #
    # === Available Components
    #   GET /rci/show/components/available
    #
    # === Install Component
    #   POST /rci/components/install
    #
    # === Remove Component
    #   POST /rci/components/remove
    #
    class Components < Base
      # Get installed components.
      #
      # @return [Array<Hash>] List of installed components
      # @example
      #   installed = client.components.installed
      #
      def installed
        response = get('/rci/show/components')
        normalize_components(response)
      end

      # Get available components for installation.
      #
      # @return [Array<Hash>] List of available components
      # @example
      #   available = client.components.available
      #
      def available
        response = get('/rci/show/components/available')
        normalize_components(response)
      end

      # Install a component.
      #
      # @param name [String] Component name
      # @return [Hash, nil] API response
      # @example
      #   client.components.install(name: 'transmission')
      #
      def install(name:)
        post('/rci/components/install', { 'name' => name })
      end

      # Remove a component.
      #
      # @param name [String] Component name
      # @return [Hash, nil] API response
      # @example
      #   client.components.remove(name: 'transmission')
      #
      def remove(name:)
        post('/rci/components/remove', { 'name' => name })
      end

      private

      def normalize_components(response)
        components_data = case response
                          when Array
                            response
                          when Hash
                            response['component'] || response['components'] || []
                          else
                            []
                          end

        return [] unless components_data.is_a?(Array)

        components_data.map { |component| normalize_component(component) }.compact
      end

      def normalize_component(data)
        return nil unless data.is_a?(Hash)

        deep_normalize_keys(data)
      end
    end
  end
end
