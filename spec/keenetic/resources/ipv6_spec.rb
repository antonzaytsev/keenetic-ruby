require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Ipv6 do
  let(:client) { Keenetic::Client.new }
  let(:ipv6) { client.ipv6 }

  before { stub_keenetic_auth }

  describe '#interfaces' do
    let(:interfaces_response) do
      {
        'interface' => [
          {
            'id' => 'Bridge0',
            'address' => 'fe80::1',
            'prefix-length' => 64,
            'state' => 'up'
          },
          {
            'id' => 'ISP',
            'address' => '2001:db8::1',
            'prefix-length' => 64,
            'state' => 'up'
          }
        ]
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/ipv6/interface')
        .to_return(status: 200, body: interfaces_response.to_json)
    end

    it 'returns list of IPv6 interfaces' do
      result = ipv6.interfaces

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first[:id]).to eq('Bridge0')
    end

    it 'includes interface details' do
      result = ipv6.interfaces

      expect(result.first[:address]).to eq('fe80::1')
      expect(result.first[:prefix_length]).to eq(64)
    end

    context 'when no interfaces' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ipv6/interface')
          .to_return(status: 200, body: '{"interface": []}')
      end

      it 'returns empty array' do
        expect(ipv6.interfaces).to eq([])
      end
    end

    context 'when response is array directly' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ipv6/interface')
          .to_return(status: 200, body: '[{"id": "Bridge0"}]')
      end

      it 'handles array response' do
        result = ipv6.interfaces

        expect(result).to be_an(Array)
        expect(result.first[:id]).to eq('Bridge0')
      end
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ipv6/interface')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty array' do
        expect(ipv6.interfaces).to eq([])
      end
    end
  end

  describe '#routes' do
    let(:routes_response) do
      {
        'route' => [
          {
            'destination' => '::/0',
            'gateway' => 'fe80::1',
            'interface' => 'ISP',
            'metric' => 1024
          },
          {
            'destination' => '2001:db8::/32',
            'gateway' => '::',
            'interface' => 'Bridge0',
            'metric' => 256
          }
        ]
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/ipv6/route')
        .to_return(status: 200, body: routes_response.to_json)
    end

    it 'returns list of IPv6 routes' do
      result = ipv6.routes

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
    end

    it 'includes route details' do
      result = ipv6.routes

      expect(result.first[:destination]).to eq('::/0')
      expect(result.first[:gateway]).to eq('fe80::1')
      expect(result.first[:metric]).to eq(1024)
    end

    context 'when no routes' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ipv6/route')
          .to_return(status: 200, body: '{"route": []}')
      end

      it 'returns empty array' do
        expect(ipv6.routes).to eq([])
      end
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ipv6/route')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty array' do
        expect(ipv6.routes).to eq([])
      end
    end
  end

  describe '#neighbors' do
    let(:neighbors_response) do
      {
        'neighbor' => [
          {
            'address' => 'fe80::1',
            'mac' => '00:11:22:33:44:55',
            'interface' => 'Bridge0',
            'state' => 'reachable'
          },
          {
            'address' => '2001:db8::100',
            'mac' => 'AA:BB:CC:DD:EE:FF',
            'interface' => 'Bridge0',
            'state' => 'stale'
          }
        ]
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/ipv6/neighbor')
        .to_return(status: 200, body: neighbors_response.to_json)
    end

    it 'returns list of IPv6 neighbors' do
      result = ipv6.neighbors

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
    end

    it 'includes neighbor details' do
      result = ipv6.neighbors

      expect(result.first[:address]).to eq('fe80::1')
      expect(result.first[:mac]).to eq('00:11:22:33:44:55')
      expect(result.first[:state]).to eq('reachable')
    end

    context 'when no neighbors' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ipv6/neighbor')
          .to_return(status: 200, body: '{"neighbor": []}')
      end

      it 'returns empty array' do
        expect(ipv6.neighbors).to eq([])
      end
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ipv6/neighbor')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty array' do
        expect(ipv6.neighbors).to eq([])
      end
    end
  end
end
