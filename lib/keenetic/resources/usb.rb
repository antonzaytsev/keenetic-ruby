module Keenetic
  module Resources
    # USB resource for managing USB devices and storage.
    #
    # == API Endpoints Used
    #
    # === Reading USB Devices
    #   GET /rci/show/usb
    #   Returns: Connected USB devices
    #
    # === Reading Storage/Media
    #   GET /rci/show/media
    #   Returns: Mounted storage partitions
    #
    # === Safely Eject USB
    #   POST /rci/usb/eject
    #   Body: { port }
    #
    class Usb < Base
      # Get connected USB devices.
      #
      # == Keenetic API Request
      #   GET /rci/show/usb
      #
      # == Response Fields (per device)
      #   - port: USB port number
      #   - manufacturer: Device manufacturer
      #   - product: Product name
      #   - serial: Serial number
      #   - class: USB device class
      #   - speed: USB speed
      #   - connected: Currently connected
      #
      # @return [Array<Hash>] List of USB devices
      # @example
      #   devices = client.usb.devices
      #   # => [{ port: 1, manufacturer: "SanDisk", product: "USB Flash", ... }]
      #
      def devices
        response = get('/rci/show/usb')
        normalize_devices(response)
      end

      # Get mounted storage partitions.
      #
      # == Keenetic API Request
      #   GET /rci/show/media
      #
      # == Response Fields (per partition)
      #   - name: Device name
      #   - label: Volume label
      #   - uuid: Volume UUID
      #   - fs: Filesystem type
      #   - mountpoint: Mount path
      #   - total: Total bytes
      #   - used: Used bytes
      #   - free: Free bytes
      #
      # @return [Array<Hash>] List of storage partitions
      # @example
      #   media = client.usb.media
      #   # => [{ name: "sda1", label: "USB_DRIVE", fs: "ext4", total: 32000000000, ... }]
      #
      def media
        response = get('/rci/show/media')
        normalize_media(response)
      end

      # Alias for media
      alias storage media

      # Safely eject a USB device.
      #
      # == Keenetic API Request
      #   POST /rci/usb/eject
      #   Body: { "port": 1 }
      #
      # @param port [Integer] USB port number to eject
      # @return [Hash, nil] API response
      #
      # @example
      #   client.usb.eject(port: 1)
      #
      def eject(port:)
        post('/rci/usb/eject', { 'port' => port })
      end

      private

      def normalize_devices(response)
        devices_data = case response
                       when Array
                         response
                       when Hash
                         response['device'] || response['devices'] || []
                       else
                         []
                       end

        return [] unless devices_data.is_a?(Array)

        devices_data.map { |device| normalize_device(device) }.compact
      end

      def normalize_device(data)
        return nil unless data.is_a?(Hash)

        result = deep_normalize_keys(data)
        normalize_booleans(result, %i[connected])
        result
      end

      def normalize_media(response)
        media_data = case response
                     when Array
                       response
                     when Hash
                       response['media'] || response['partition'] || []
                     else
                       []
                     end

        return [] unless media_data.is_a?(Array)

        media_data.map { |partition| normalize_partition(partition) }.compact
      end

      def normalize_partition(data)
        return nil unless data.is_a?(Hash)

        deep_normalize_keys(data)
      end
    end
  end
end
