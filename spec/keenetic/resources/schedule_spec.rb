require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Schedule do
  let(:client) { Keenetic::Client.new }
  let(:schedule) { client.schedule }

  before { stub_keenetic_auth }

  describe '#all' do
    let(:schedules_response) do
      {
        'schedule' => [
          {
            'name' => 'kids_bedtime',
            'entries' => [
              { 'days' => 'mon,tue,wed,thu,fri', 'start' => '22:00', 'end' => '07:00', 'action' => 'deny' }
            ]
          },
          {
            'name' => 'weekend_gaming',
            'entries' => [
              { 'days' => 'sat,sun', 'start' => '10:00', 'end' => '22:00', 'action' => 'permit' }
            ]
          }
        ]
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/schedule')
        .to_return(status: 200, body: schedules_response.to_json)
    end

    it 'returns list of schedules' do
      result = schedule.all

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first[:name]).to eq('kids_bedtime')
    end

    it 'includes schedule entries' do
      result = schedule.all

      expect(result.first[:entries]).to be_an(Array)
      expect(result.first[:entries].first[:days]).to eq('mon,tue,wed,thu,fri')
    end

    context 'when no schedules exist' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/schedule')
          .to_return(status: 200, body: '{"schedule": []}')
      end

      it 'returns empty array' do
        expect(schedule.all).to eq([])
      end
    end

    context 'when response is array directly' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/schedule')
          .to_return(status: 200, body: '[{"name": "test"}]')
      end

      it 'handles array response' do
        result = schedule.all

        expect(result).to be_an(Array)
        expect(result.first[:name]).to eq('test')
      end
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/schedule')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty array' do
        expect(schedule.all).to eq([])
      end
    end
  end

  describe '#find' do
    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/schedule')
        .to_return(status: 200, body: '{"schedule": [{"name": "test"}, {"name": "other"}]}')
    end

    it 'finds schedule by name' do
      result = schedule.find('test')

      expect(result[:name]).to eq('test')
    end

    it 'returns nil when not found' do
      result = schedule.find('nonexistent')

      expect(result).to be_nil
    end
  end

  describe '#create' do
    it 'creates a new schedule' do
      create_stub = stub_request(:post, 'http://192.168.1.1/rci/schedule')
        .with { |req|
          body = JSON.parse(req.body)
          body['name'] == 'kids_bedtime' && body['entries'].is_a?(Array)
        }
        .to_return(status: 200, body: '{}')

      schedule.create(
        name: 'kids_bedtime',
        entries: [{ 'days' => 'mon,tue', 'start' => '22:00', 'end' => '07:00', 'action' => 'deny' }]
      )

      expect(create_stub).to have_been_requested
    end
  end

  describe '#delete' do
    it 'deletes schedule by name' do
      delete_stub = stub_request(:post, 'http://192.168.1.1/rci/schedule')
        .with(body: { 'name' => 'kids_bedtime', 'no' => true }.to_json)
        .to_return(status: 200, body: '{}')

      schedule.delete(name: 'kids_bedtime')

      expect(delete_stub).to have_been_requested
    end
  end
end
