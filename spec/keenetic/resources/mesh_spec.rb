require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Mesh do
  let(:client) { Keenetic::Client.new }
  let(:mesh) { client.mesh }

  before { stub_keenetic_auth }

  describe '#status' do
    let(:status_response) do
      {
        'enabled' => true,
        'role' => 'controller',
        'members-count' => 2,
        'ssid' => 'MyNetwork',
        'channel' => 6,
        'active' => true
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/mws')
        .to_return(status: 200, body: status_response.to_json)
    end

    it 'returns mesh system status' do
      result = mesh.status

      expect(result[:enabled]).to eq(true)
      expect(result[:role]).to eq('controller')
      expect(result[:ssid]).to eq('MyNetwork')
    end

    it 'normalizes kebab-case keys' do
      result = mesh.status

      expect(result).to have_key(:members_count)
      expect(result[:members_count]).to eq(2)
    end

    it 'normalizes boolean values' do
      result = mesh.status

      expect(result[:enabled]).to eq(true)
      expect(result[:active]).to eq(true)
    end

    context 'when mesh is disabled' do
      let(:status_response) do
        {
          'enabled' => false,
          'role' => 'standalone'
        }
      end

      it 'returns disabled status' do
        result = mesh.status

        expect(result[:enabled]).to eq(false)
        expect(result[:role]).to eq('standalone')
      end
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/mws')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty hash' do
        expect(mesh.status).to eq({})
      end
    end

    context 'when response is not a hash' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/mws')
          .to_return(status: 200, body: '[]')
      end

      it 'returns empty hash' do
        expect(mesh.status).to eq({})
      end
    end
  end

  describe '#members' do
    let(:members_response) do
      {
        'member' => [
          {
            'mac' => 'AA:BB:CC:DD:EE:FF',
            'name' => 'Living Room Extender',
            'mode' => 'extender',
            'online' => true,
            'ip' => '192.168.1.50',
            'uptime' => 86400,
            'signal-strength' => -45
          },
          {
            'mac' => '11:22:33:44:55:66',
            'name' => 'Bedroom Extender',
            'mode' => 'extender',
            'online' => true,
            'ip' => '192.168.1.51',
            'uptime' => 43200,
            'signal-strength' => -55
          }
        ]
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/mws/member')
        .to_return(status: 200, body: members_response.to_json)
    end

    it 'returns list of mesh members' do
      result = mesh.members

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first[:mac]).to eq('AA:BB:CC:DD:EE:FF')
      expect(result.first[:name]).to eq('Living Room Extender')
    end

    it 'normalizes member data' do
      result = mesh.members

      expect(result.first[:mode]).to eq('extender')
      expect(result.first[:ip]).to eq('192.168.1.50')
      expect(result.first[:uptime]).to eq(86400)
    end

    it 'normalizes kebab-case keys' do
      result = mesh.members

      expect(result.first).to have_key(:signal_strength)
      expect(result.first[:signal_strength]).to eq(-45)
    end

    it 'normalizes boolean values' do
      result = mesh.members

      expect(result.first[:online]).to eq(true)
    end

    context 'when response is array directly' do
      let(:members_response) do
        [
          { 'mac' => 'AA:BB:CC:DD:EE:FF', 'name' => 'Extender 1', 'online' => true }
        ]
      end

      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/mws/member')
          .to_return(status: 200, body: members_response.to_json)
      end

      it 'handles array response' do
        result = mesh.members

        expect(result).to be_an(Array)
        expect(result.size).to eq(1)
        expect(result.first[:mac]).to eq('AA:BB:CC:DD:EE:FF')
      end
    end

    context 'when no members exist' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/mws/member')
          .to_return(status: 200, body: '{"member": []}')
      end

      it 'returns empty array' do
        expect(mesh.members).to eq([])
      end
    end

    context 'when response is empty hash' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/mws/member')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty array' do
        expect(mesh.members).to eq([])
      end
    end

    context 'when response is not valid' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/mws/member')
          .to_return(status: 200, body: '"invalid"')
      end

      it 'returns empty array' do
        expect(mesh.members).to eq([])
      end
    end
  end
end
