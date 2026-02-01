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
    # === Upload Configuration
    #   POST /ci/startup-config.txt
    #   Body: Plain text configuration file
    #   Restores configuration from backup
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
      #   config_text = client.system_config.download
      #   File.write('router-backup.txt', config_text)
      #
      def download
        get('/ci/startup-config.txt')
      end

      # Upload and restore a configuration file.
      #
      # == Keenetic API Request
      #   POST /ci/startup-config.txt
      #   Content-Type: text/plain
      #   Body: Configuration file content
      #
      # Uploads a configuration file to the router. The configuration
      # will be applied after a reboot.
      #
      # == Warning
      # This is a potentially destructive operation. Uploading an
      # invalid or incompatible configuration may make the router
      # inaccessible. Always ensure you have physical access to the
      # router before restoring configuration.
      #
      # @param content [String] Configuration file content
      # @return [String, nil] Response from the router
      # @example Upload from string
      #   client.system_config.upload(config_text)
      #
      # @example Upload from file
      #   config_text = File.read('router-backup.txt')
      #   client.system_config.upload(config_text)
      #
      def upload(content)
        raise ArgumentError, 'Configuration content cannot be empty' if content.nil? || content.strip.empty?

        post_raw('/ci/startup-config.txt', content)
      end
    end
  end
end
