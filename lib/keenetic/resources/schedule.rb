module Keenetic
  module Resources
    # Schedule resource for managing access control schedules.
    #
    # == API Endpoints Used
    #
    # === List Schedules
    #   GET /rci/show/schedule
    #
    # === Create Schedule
    #   POST /rci/schedule
    #
    # === Delete Schedule
    #   POST /rci/schedule with { "name": "...", "no": true }
    #
    class Schedule < Base
      # List all schedules.
      #
      # @return [Array<Hash>] List of schedules
      # @example
      #   schedules = client.schedule.all
      #
      def all
        response = get('/rci/show/schedule')
        normalize_schedules(response)
      end

      # Find a schedule by name.
      #
      # @param name [String] Schedule name
      # @return [Hash, nil] Schedule data or nil
      #
      def find(name)
        all.find { |s| s[:name] == name }
      end

      # Create a new schedule.
      #
      # @param name [String] Schedule name
      # @param entries [Array<Hash>] Schedule entries with days, start, end, action
      # @return [Hash, nil] API response
      # @example
      #   client.schedule.create(
      #     name: 'kids_bedtime',
      #     entries: [
      #       { days: 'mon,tue,wed,thu,fri', start: '22:00', end: '07:00', action: 'deny' }
      #     ]
      #   )
      #
      def create(name:, entries:)
        post('/rci/schedule', { 'name' => name, 'entries' => entries })
      end

      # Delete a schedule.
      #
      # @param name [String] Schedule name
      # @return [Hash, nil] API response
      #
      def delete(name:)
        post('/rci/schedule', { 'name' => name, 'no' => true })
      end

      private

      def normalize_schedules(response)
        schedules_data = case response
                         when Array
                           response
                         when Hash
                           response['schedule'] || response['schedules'] || []
                         else
                           []
                         end

        return [] unless schedules_data.is_a?(Array)

        schedules_data.map { |schedule| normalize_schedule(schedule) }.compact
      end

      def normalize_schedule(data)
        return nil unless data.is_a?(Hash)

        deep_normalize_keys(data)
      end
    end
  end
end
