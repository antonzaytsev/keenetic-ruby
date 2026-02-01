require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Vpn do
  let(:client) { Keenetic::Client.new }
  let(:vpn) { client.vpn }

  before { stub_keenetic_auth }

  describe '#status' do
    let(:status_response) do
      {
        'type' => 'l2tp',
        'enabled' => true,
        'running' => true,
        'pool-start' => '192.168.1.200',
        'pool-end' => '192.168.1.210',
        'interface' => 'PPTP0',
        'mppe' => 'require'
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/vpn-server')
        .to_return(status: 200, body: status_response.to_json)
    end

    it 'returns normalized VPN server status' do
      result = vpn.status

      expect(result[:type]).to eq('l2tp')
      expect(result[:enabled]).to eq(true)
      expect(result[:running]).to eq(true)
      expect(result[:pool_start]).to eq('192.168.1.200')
      expect(result[:pool_end]).to eq('192.168.1.210')
      expect(result[:interface]).to eq('PPTP0')
    end

    it 'normalizes kebab-case keys to snake_case' do
      result = vpn.status

      expect(result).to have_key(:pool_start)
      expect(result).to have_key(:pool_end)
      expect(result).not_to have_key(:'pool-start')
    end

    it 'normalizes boolean values' do
      result = vpn.status

      expect(result[:enabled]).to eq(true)
      expect(result[:running]).to eq(true)
    end

    context 'when VPN server is disabled' do
      let(:status_response) do
        {
          'type' => 'pptp',
          'enabled' => false,
          'running' => false
        }
      end

      it 'returns disabled status' do
        result = vpn.status

        expect(result[:enabled]).to eq(false)
        expect(result[:running]).to eq(false)
      end
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/vpn-server')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty hash' do
        expect(vpn.status).to eq({})
      end
    end

    context 'when response is not a hash' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/vpn-server')
          .to_return(status: 200, body: '[]')
      end

      it 'returns empty hash' do
        expect(vpn.status).to eq({})
      end
    end
  end

  describe '#clients' do
    let(:clients_response) do
      [
        {
          'name' => 'user1',
          'ip' => '192.168.1.200',
          'uptime' => 3600,
          'rxbytes' => 1048576,
          'txbytes' => 524288,
          'interface' => 'PPTP0'
        },
        {
          'name' => 'user2',
          'ip' => '192.168.1.201',
          'uptime' => 1800,
          'rxbytes' => 2097152,
          'txbytes' => 1048576,
          'interface' => 'PPTP0'
        }
      ]
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/vpn-server/clients')
        .to_return(status: 200, body: clients_response.to_json)
    end

    it 'returns normalized list of VPN clients' do
      result = vpn.clients

      expect(result.size).to eq(2)
      expect(result.first[:name]).to eq('user1')
      expect(result.first[:ip]).to eq('192.168.1.200')
      expect(result.first[:uptime]).to eq(3600)
      expect(result.first[:rxbytes]).to eq(1048576)
      expect(result.first[:txbytes]).to eq(524288)
    end

    context 'when no clients are connected' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/vpn-server/clients')
          .to_return(status: 200, body: '[]')
      end

      it 'returns empty array' do
        expect(vpn.clients).to eq([])
      end
    end

    context 'when response is not an array' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/vpn-server/clients')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty array' do
        expect(vpn.clients).to eq([])
      end
    end
  end

  describe '#ipsec_status' do
    let(:ipsec_response) do
      {
        'established' => 2,
        'sa' => [
          {
            'name' => 'vpn-tunnel-1',
            'state' => 'established',
            'local-id' => '192.168.1.1',
            'remote-id' => '10.0.0.1',
            'uptime' => 7200
          },
          {
            'name' => 'vpn-tunnel-2',
            'state' => 'established',
            'local-id' => '192.168.1.1',
            'remote-id' => '10.0.0.2',
            'uptime' => 3600
          }
        ]
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/crypto/ipsec/sa')
        .to_return(status: 200, body: ipsec_response.to_json)
    end

    it 'returns normalized IPsec status' do
      result = vpn.ipsec_status

      expect(result[:established]).to eq(2)
      expect(result[:sa]).to be_an(Array)
      expect(result[:sa].size).to eq(2)
    end

    it 'normalizes nested kebab-case keys' do
      result = vpn.ipsec_status

      expect(result[:sa].first[:local_id]).to eq('192.168.1.1')
      expect(result[:sa].first[:remote_id]).to eq('10.0.0.1')
    end

    context 'when no IPsec tunnels are established' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/crypto/ipsec/sa')
          .to_return(status: 200, body: '{"established": 0, "sa": []}')
      end

      it 'returns status with empty sa array' do
        result = vpn.ipsec_status

        expect(result[:established]).to eq(0)
        expect(result[:sa]).to eq([])
      end
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/crypto/ipsec/sa')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty hash' do
        expect(vpn.ipsec_status).to eq({})
      end
    end

    context 'when response is not a hash' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/crypto/ipsec/sa')
          .to_return(status: 200, body: '[]')
      end

      it 'returns empty hash' do
        expect(vpn.ipsec_status).to eq({})
      end
    end
  end

  describe '#configure' do
    it 'sends configuration with all parameters' do
      config_stub = stub_request(:post, 'http://192.168.1.1/rci/vpn-server')
        .with { |request|
          body = JSON.parse(request.body)
          body['type'] == 'l2tp' &&
            body['enabled'] == true &&
            body['pool-start'] == '192.168.1.200' &&
            body['pool-end'] == '192.168.1.210' &&
            body['mppe'] == 'require'
        }
        .to_return(status: 200, body: '{}')

      vpn.configure(
        type: 'l2tp',
        enabled: true,
        pool_start: '192.168.1.200',
        pool_end: '192.168.1.210',
        mppe: 'require'
      )

      expect(config_stub).to have_been_requested
    end

    it 'sends minimal configuration' do
      config_stub = stub_request(:post, 'http://192.168.1.1/rci/vpn-server')
        .with { |request|
          body = JSON.parse(request.body)
          body['type'] == 'pptp' &&
            body['enabled'] == false &&
            !body.key?('pool-start') &&
            !body.key?('pool-end')
        }
        .to_return(status: 200, body: '{}')

      vpn.configure(type: 'pptp', enabled: false)

      expect(config_stub).to have_been_requested
    end

    it 'sends configuration with pool range only' do
      config_stub = stub_request(:post, 'http://192.168.1.1/rci/vpn-server')
        .with { |request|
          body = JSON.parse(request.body)
          body['type'] == 'sstp' &&
            body['enabled'] == true &&
            body['pool-start'] == '10.0.0.100' &&
            body['pool-end'] == '10.0.0.150' &&
            !body.key?('mppe')
        }
        .to_return(status: 200, body: '{}')

      vpn.configure(
        type: 'sstp',
        enabled: true,
        pool_start: '10.0.0.100',
        pool_end: '10.0.0.150'
      )

      expect(config_stub).to have_been_requested
    end
  end
end
