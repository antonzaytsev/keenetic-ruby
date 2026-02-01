require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Hotspot do
  let(:client) { Keenetic::Client.new }
  let(:hotspot) { client.hotspot }

  before { stub_keenetic_auth }

  describe '#policies' do
    let(:policies_response) do
      [
        {
          'show' => {
            'sc' => {
              'ip' => {
                'policy' => [
                  {
                    'id' => 'Policy0',
                    'description' => 'VPN Policy',
                    'global' => false,
                    'interface' => [
                      { 'name' => 'Wireguard0', 'priority' => 100 }
                    ]
                  },
                  {
                    'id' => 'Policy1',
                    'description' => 'Direct',
                    'global' => true,
                    'interface' => []
                  }
                ]
              }
            }
          }
        }
      ]
    end

    before do
      stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [{ 'show' => { 'sc' => { 'ip' => { 'policy' => {} } } } }].to_json)
        .to_return(status: 200, body: policies_response.to_json)
    end

    it 'returns normalized list of policies' do
      result = hotspot.policies

      expect(result.size).to eq(2)
      expect(result.first[:id]).to eq('Policy0')
      expect(result.first[:description]).to eq('VPN Policy')
      expect(result.first[:global]).to eq(false)
      expect(result.first[:interfaces].first[:name]).to eq('Wireguard0')
      expect(result.first[:interfaces].first[:priority]).to eq(100)
    end

    it 'handles global policies with no interfaces' do
      result = hotspot.policies

      expect(result.last[:id]).to eq('Policy1')
      expect(result.last[:global]).to eq(true)
      expect(result.last[:interfaces]).to eq([])
    end

    context 'when response is empty' do
      before do
        stub_request(:post, 'http://192.168.1.1/rci/')
          .with(body: [{ 'show' => { 'sc' => { 'ip' => { 'policy' => {} } } } }].to_json)
          .to_return(status: 200, body: [{ 'show' => { 'sc' => { 'ip' => { 'policy' => [] } } } }].to_json)
      end

      it 'returns empty array' do
        expect(hotspot.policies).to eq([])
      end
    end
  end

  describe '#hosts' do
    let(:hosts_response) do
      [
        {
          'show' => {
            'sc' => {
              'ip' => {
                'hotspot' => {
                  'host' => [
                    {
                      'mac' => 'AA:BB:CC:DD:EE:FF',
                      'name' => 'My Device',
                      'policy' => 'Policy0',
                      'permit' => true
                    }
                  ]
                }
              }
            }
          }
        },
        {
          'show' => {
            'ip' => {
              'hotspot' => {
                'host' => [
                  {
                    'mac' => 'AA:BB:CC:DD:EE:FF',
                    'hostname' => 'device-hostname',
                    'ip' => '192.168.1.100',
                    'interface' => 'Bridge0',
                    'active' => true,
                    'access' => 'permit',
                    'rxbytes' => 12345,
                    'txbytes' => 67890
                  },
                  {
                    'mac' => '11:22:33:44:55:66',
                    'hostname' => 'unknown-device',
                    'ip' => '192.168.1.101',
                    'interface' => 'Bridge0',
                    'active' => true
                  }
                ]
              }
            }
          }
        }
      ]
    end

    before do
      stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [
          { 'show' => { 'sc' => { 'ip' => { 'hotspot' => { 'host' => {} } } } } },
          { 'show' => { 'ip' => { 'hotspot' => {} } } }
        ].to_json)
        .to_return(status: 200, body: hosts_response.to_json)
    end

    it 'returns merged config and runtime host data' do
      result = hotspot.hosts

      expect(result.size).to eq(2)

      # First host has both config and runtime data
      configured_host = result.find { |h| h[:mac] == 'AA:BB:CC:DD:EE:FF' }
      expect(configured_host[:name]).to eq('My Device')
      expect(configured_host[:policy]).to eq('Policy0')
      expect(configured_host[:permit]).to eq(true)
      expect(configured_host[:ip]).to eq('192.168.1.100')
      expect(configured_host[:active]).to eq(true)
      expect(configured_host[:rxbytes]).to eq(12345)
    end

    it 'includes runtime-only hosts' do
      result = hotspot.hosts

      runtime_host = result.find { |h| h[:mac] == '11:22:33:44:55:66' }
      expect(runtime_host).not_to be_nil
      expect(runtime_host[:hostname]).to eq('unknown-device')
      expect(runtime_host[:ip]).to eq('192.168.1.101')
      expect(runtime_host[:policy]).to be_nil
    end

    context 'when response is empty' do
      before do
        stub_request(:post, 'http://192.168.1.1/rci/')
          .with(body: [
            { 'show' => { 'sc' => { 'ip' => { 'hotspot' => { 'host' => {} } } } } },
            { 'show' => { 'ip' => { 'hotspot' => {} } } }
          ].to_json)
          .to_return(status: 200, body: [
            { 'show' => { 'sc' => { 'ip' => { 'hotspot' => { 'host' => [] } } } } },
            { 'show' => { 'ip' => { 'hotspot' => { 'host' => [] } } } }
          ].to_json)
      end

      it 'returns empty array' do
        expect(hotspot.hosts).to eq([])
      end
    end
  end

  describe '#set_host_policy' do
    it 'sends set policy command' do
      set_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [
          { 'webhelp' => { 'event' => { 'push' => { 'data' => '{"type":"configuration_change","value":{"url":"/policies/policy-consumers"}}' } } } },
          { 'ip' => { 'hotspot' => { 'host' => {
            'mac' => 'aa:bb:cc:dd:ee:ff',
            'permit' => true,
            'policy' => 'Policy0'
          } } } },
          { 'system' => { 'configuration' => { 'save' => {} } } }
        ].to_json)
        .to_return(status: 200, body: '[{}, {}, {}]')

      hotspot.set_host_policy(mac: 'AA:BB:CC:DD:EE:FF', policy: 'Policy0')

      expect(set_stub).to have_been_requested
    end

    it 'sends remove policy command when policy is nil' do
      set_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [
          { 'webhelp' => { 'event' => { 'push' => { 'data' => '{"type":"configuration_change","value":{"url":"/policies/policy-consumers"}}' } } } },
          { 'ip' => { 'hotspot' => { 'host' => {
            'mac' => 'aa:bb:cc:dd:ee:ff',
            'permit' => true,
            'policy' => { 'no' => true }
          } } } },
          { 'system' => { 'configuration' => { 'save' => {} } } }
        ].to_json)
        .to_return(status: 200, body: '[{}, {}, {}]')

      hotspot.set_host_policy(mac: 'AA:BB:CC:DD:EE:FF', policy: nil)

      expect(set_stub).to have_been_requested
    end

    it 'sends remove policy command when policy is empty string' do
      set_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [
          { 'webhelp' => { 'event' => { 'push' => { 'data' => '{"type":"configuration_change","value":{"url":"/policies/policy-consumers"}}' } } } },
          { 'ip' => { 'hotspot' => { 'host' => {
            'mac' => 'aa:bb:cc:dd:ee:ff',
            'permit' => true,
            'policy' => { 'no' => true }
          } } } },
          { 'system' => { 'configuration' => { 'save' => {} } } }
        ].to_json)
        .to_return(status: 200, body: '[{}, {}, {}]')

      hotspot.set_host_policy(mac: 'AA:BB:CC:DD:EE:FF', policy: '')

      expect(set_stub).to have_been_requested
    end

    it 'can set permit to false' do
      set_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [
          { 'webhelp' => { 'event' => { 'push' => { 'data' => '{"type":"configuration_change","value":{"url":"/policies/policy-consumers"}}' } } } },
          { 'ip' => { 'hotspot' => { 'host' => {
            'mac' => 'aa:bb:cc:dd:ee:ff',
            'permit' => false,
            'policy' => 'Policy0'
          } } } },
          { 'system' => { 'configuration' => { 'save' => {} } } }
        ].to_json)
        .to_return(status: 200, body: '[{}, {}, {}]')

      hotspot.set_host_policy(mac: 'AA:BB:CC:DD:EE:FF', policy: 'Policy0', permit: false)

      expect(set_stub).to have_been_requested
    end

    it 'normalizes MAC to lowercase' do
      set_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [
          { 'webhelp' => { 'event' => { 'push' => { 'data' => '{"type":"configuration_change","value":{"url":"/policies/policy-consumers"}}' } } } },
          { 'ip' => { 'hotspot' => { 'host' => {
            'mac' => 'aa:bb:cc:dd:ee:ff',
            'permit' => true,
            'policy' => 'Policy0'
          } } } },
          { 'system' => { 'configuration' => { 'save' => {} } } }
        ].to_json)
        .to_return(status: 200, body: '[{}, {}, {}]')

      hotspot.set_host_policy(mac: 'Aa:Bb:Cc:Dd:Ee:Ff', policy: 'Policy0')

      expect(set_stub).to have_been_requested
    end

    it 'raises ArgumentError when MAC is missing' do
      expect { hotspot.set_host_policy(mac: nil, policy: 'Policy0') }.to raise_error(ArgumentError, /MAC address is required/)
      expect { hotspot.set_host_policy(mac: '', policy: 'Policy0') }.to raise_error(ArgumentError, /MAC address is required/)
    end
  end

  describe '#find_policy' do
    before do
      stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [{ 'show' => { 'sc' => { 'ip' => { 'policy' => {} } } } }].to_json)
        .to_return(status: 200, body: [
          {
            'show' => {
              'sc' => {
                'ip' => {
                  'policy' => [
                    { 'id' => 'Policy0', 'description' => 'VPN' },
                    { 'id' => 'Policy1', 'description' => 'Direct' }
                  ]
                }
              }
            }
          }
        ].to_json)
    end

    it 'finds policy by id' do
      result = hotspot.find_policy(id: 'Policy0')

      expect(result[:id]).to eq('Policy0')
      expect(result[:description]).to eq('VPN')
    end

    it 'returns nil for unknown policy' do
      expect(hotspot.find_policy(id: 'UnknownPolicy')).to be_nil
    end
  end

  describe '#find_host' do
    before do
      stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [
          { 'show' => { 'sc' => { 'ip' => { 'hotspot' => { 'host' => {} } } } } },
          { 'show' => { 'ip' => { 'hotspot' => {} } } }
        ].to_json)
        .to_return(status: 200, body: [
          { 'show' => { 'sc' => { 'ip' => { 'hotspot' => { 'host' => [{ 'mac' => 'AA:BB:CC:DD:EE:FF', 'name' => 'Test' }] } } } } },
          { 'show' => { 'ip' => { 'hotspot' => { 'host' => [{ 'mac' => 'AA:BB:CC:DD:EE:FF', 'ip' => '192.168.1.100' }] } } } }
        ].to_json)
    end

    it 'finds host by MAC address' do
      result = hotspot.find_host(mac: 'AA:BB:CC:DD:EE:FF')

      expect(result[:mac]).to eq('AA:BB:CC:DD:EE:FF')
      expect(result[:name]).to eq('Test')
    end

    it 'finds host with case-insensitive MAC' do
      result = hotspot.find_host(mac: 'aa:bb:cc:dd:ee:ff')

      expect(result[:mac]).to eq('AA:BB:CC:DD:EE:FF')
    end

    it 'returns nil for unknown MAC' do
      expect(hotspot.find_host(mac: '00:00:00:00:00:00')).to be_nil
    end
  end
end
