module Keenetic
  module Resources
    # Manages router configuration operations.
    #
    # == API Endpoints Used
    #
    # === Save Configuration
    #   POST /rci/ (batch format)
    #   Body: [{"system": {"configuration": {"save": {}}}}]
    #   Saves current configuration to persistent storage
    #
    # === Download Configuration
    #   GET /ci/startup-config.txt
    #   Returns: Plain text configuration file
    #
    class Config < Base
      # Save current configuration to persistent storage.
      #
      # == Keenetic API Request
      #   POST /rci/ (batch format)
      #   Body: [{"system": {"configuration": {"save": {}}}}]
      #
      # Configuration changes are typically auto-saved, but this method
      # forces an immediate save to flash storage.
      #
      # @return [Array<Hash>] API response
      # @example
      #   client.config.save
      #   # => [{ "system" => { "configuration" => { "save" => {} } } }]
      #
      def save
        client.batch([{ 'system' => { 'configuration' => { 'save' => {} } } }])
      end

      # Download the startup configuration file.
      #
      # == Keenetic API Request
      #   GET /ci/startup-config.txt
      #
      # Returns the full router configuration as a text file.
      # This is the same format used for backup/restore operations.
      #
      # @return [String] Configuration file content
      # @example
      #   config_text = client.config.download
      #   File.write('router-backup.txt', config_text)
      #
      def download
        get('/ci/startup-config.txt')
      end
    end
  end
end
