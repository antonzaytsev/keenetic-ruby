module Keenetic
  module Resources
    # Users resource for managing router user accounts.
    #
    # == API Endpoints Used
    #
    # === List Users
    #   GET /rci/show/user
    #
    # === Create User
    #   POST /rci/user
    #
    # === Delete User
    #   POST /rci/user with { "name": "...", "no": true }
    #
    # == User Tags (permissions)
    #   - http: Web interface access
    #   - cli: CLI/Telnet access
    #   - cifs: File sharing access
    #   - ftp: FTP access
    #   - vpn: VPN access
    #
    class Users < Base
      # List all users.
      #
      # @return [Array<Hash>] List of users
      # @example
      #   users = client.users.all
      #
      def all
        response = get('/rci/show/user')
        normalize_users(response)
      end

      # Find a user by name.
      #
      # @param name [String] User name
      # @return [Hash, nil] User data or nil
      #
      def find(name)
        all.find { |u| u[:name] == name }
      end

      # Create a new user.
      #
      # @param name [String] User name
      # @param password [String] User password
      # @param tag [Array<String>] Permission tags (http, cli, cifs, ftp, vpn)
      # @return [Hash, nil] API response
      # @example
      #   client.users.create(name: 'guest', password: 'guestpass', tag: ['http', 'cifs'])
      #
      def create(name:, password:, tag: [])
        params = { 'name' => name, 'password' => password }
        params['tag'] = tag unless tag.empty?
        post('/rci/user', params)
      end

      # Delete a user.
      #
      # @param name [String] User name
      # @return [Hash, nil] API response
      #
      def delete(name:)
        post('/rci/user', { 'name' => name, 'no' => true })
      end

      private

      def normalize_users(response)
        users_data = case response
                     when Array
                       response
                     when Hash
                       response['user'] || response['users'] || []
                     else
                       []
                     end

        return [] unless users_data.is_a?(Array)

        users_data.map { |user| normalize_user(user) }.compact
      end

      def normalize_user(data)
        return nil unless data.is_a?(Hash)

        deep_normalize_keys(data)
      end
    end
  end
end
