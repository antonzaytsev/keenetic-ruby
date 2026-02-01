require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Qos do
  let(:client) { Keenetic::Client.new }
  let(:qos) { client.qos }

  before { stub_keenetic_auth }

  describe '#traffic_shaper' do
    let(:shaper_response) do
      {
        'enabled' => true,
        'upload-rate' => 100000,
        'download-rate' => 500000,
        'interface' => 'ISP'
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/ip/traffic-control')
        .to_return(status: 200, body: shaper_response.to_json)
    end

    it 'returns traffic shaper status' do
      result = qos.traffic_shaper

      expect(result).to be_a(Hash)
      expect(result[:enabled]).to eq(true)
    end

    it 'includes rate limits' do
      result = qos.traffic_shaper

      expect(result[:upload_rate]).to eq(100000)
      expect(result[:download_rate]).to eq(500000)
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ip/traffic-control')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty hash' do
        expect(qos.traffic_shaper).to eq({})
      end
    end
  end

  describe '#shaper' do
    it 'is an alias for traffic_shaper' do
      stub_request(:get, 'http://192.168.1.1/rci/show/ip/traffic-control')
        .to_return(status: 200, body: '{}')

      expect(qos.method(:shaper)).to eq(qos.method(:traffic_shaper))
    end
  end

  describe '#intelliqos' do
    let(:qos_response) do
      {
        'enabled' => true,
        'mode' => 'auto',
        'wan-bandwidth' => 100000000
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/ip/qos')
        .to_return(status: 200, body: qos_response.to_json)
    end

    it 'returns IntelliQoS settings' do
      result = qos.intelliqos

      expect(result).to be_a(Hash)
      expect(result[:enabled]).to eq(true)
      expect(result[:mode]).to eq('auto')
    end

    it 'normalizes kebab-case keys' do
      result = qos.intelliqos

      expect(result[:wan_bandwidth]).to eq(100000000)
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ip/qos')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty hash' do
        expect(qos.intelliqos).to eq({})
      end
    end
  end

  describe '#settings' do
    it 'is an alias for intelliqos' do
      stub_request(:get, 'http://192.168.1.1/rci/show/ip/qos')
        .to_return(status: 200, body: '{}')

      expect(qos.method(:settings)).to eq(qos.method(:intelliqos))
    end
  end

  describe '#traffic_stats' do
    let(:stats_response) do
      {
        'host' => [
          {
            'mac' => '00:11:22:33:44:55',
            'ip' => '192.168.1.100',
            'rx-bytes' => 1000000,
            'tx-bytes' => 500000,
            'rx-rate' => 1000,
            'tx-rate' => 500
          },
          {
            'mac' => 'AA:BB:CC:DD:EE:FF',
            'ip' => '192.168.1.101',
            'rx-bytes' => 2000000,
            'tx-bytes' => 1000000,
            'rx-rate' => 2000,
            'tx-rate' => 1000
          }
        ]
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/ip/hotspot/summary')
        .to_return(status: 200, body: stats_response.to_json)
    end

    it 'returns traffic statistics by host' do
      result = qos.traffic_stats

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
    end

    it 'includes traffic details' do
      result = qos.traffic_stats

      expect(result.first[:mac]).to eq('00:11:22:33:44:55')
      expect(result.first[:rx_bytes]).to eq(1000000)
      expect(result.first[:tx_rate]).to eq(500)
    end

    context 'when no hosts' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ip/hotspot/summary')
          .to_return(status: 200, body: '{"host": []}')
      end

      it 'returns empty array' do
        expect(qos.traffic_stats).to eq([])
      end
    end

    context 'when response is array directly' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ip/hotspot/summary')
          .to_return(status: 200, body: '[{"mac": "00:11:22:33:44:55"}]')
      end

      it 'handles array response' do
        result = qos.traffic_stats

        expect(result).to be_an(Array)
        expect(result.first[:mac]).to eq('00:11:22:33:44:55')
      end
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ip/hotspot/summary')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty array' do
        expect(qos.traffic_stats).to eq([])
      end
    end
  end

  describe '#host_stats' do
    it 'is an alias for traffic_stats' do
      stub_request(:get, 'http://192.168.1.1/rci/show/ip/hotspot/summary')
        .to_return(status: 200, body: '{}')

      expect(qos.method(:host_stats)).to eq(qos.method(:traffic_stats))
    end
  end
end
