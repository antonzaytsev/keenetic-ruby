require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Diagnostics do
  let(:client) { Keenetic::Client.new }
  let(:diagnostics) { client.diagnostics }

  before { stub_keenetic_auth }

  describe '#ping' do
    let(:ping_response) do
      {
        'host' => '8.8.8.8',
        'transmitted' => 4,
        'received' => 4,
        'packet-loss' => 0,
        'min' => 10,
        'avg' => 15,
        'max' => 25,
        'mdev' => 5
      }
    end

    it 'sends ping request with default count' do
      ping_stub = stub_request(:post, 'http://192.168.1.1/rci/tools/ping')
        .with(body: { 'host' => '8.8.8.8', 'count' => 4 }.to_json)
        .to_return(status: 200, body: ping_response.to_json)

      result = diagnostics.ping('8.8.8.8')

      expect(ping_stub).to have_been_requested
      expect(result[:host]).to eq('8.8.8.8')
      expect(result[:transmitted]).to eq(4)
      expect(result[:received]).to eq(4)
    end

    it 'sends ping request with custom count' do
      ping_stub = stub_request(:post, 'http://192.168.1.1/rci/tools/ping')
        .with(body: { 'host' => 'google.com', 'count' => 10 }.to_json)
        .to_return(status: 200, body: ping_response.to_json)

      diagnostics.ping('google.com', count: 10)

      expect(ping_stub).to have_been_requested
    end

    it 'normalizes kebab-case keys' do
      stub_request(:post, 'http://192.168.1.1/rci/tools/ping')
        .to_return(status: 200, body: ping_response.to_json)

      result = diagnostics.ping('8.8.8.8')

      expect(result).to have_key(:packet_loss)
      expect(result[:packet_loss]).to eq(0)
    end

    context 'when host is unreachable' do
      let(:ping_response) do
        {
          'host' => '10.255.255.1',
          'transmitted' => 4,
          'received' => 0,
          'packet-loss' => 100
        }
      end

      it 'returns packet loss data' do
        stub_request(:post, 'http://192.168.1.1/rci/tools/ping')
          .to_return(status: 200, body: ping_response.to_json)

        result = diagnostics.ping('10.255.255.1')

        expect(result[:received]).to eq(0)
        expect(result[:packet_loss]).to eq(100)
      end
    end

    context 'when response is empty' do
      it 'returns empty hash' do
        stub_request(:post, 'http://192.168.1.1/rci/tools/ping')
          .to_return(status: 200, body: '{}')

        expect(diagnostics.ping('8.8.8.8')).to eq({})
      end
    end

    context 'when response is not a hash' do
      it 'returns empty hash' do
        stub_request(:post, 'http://192.168.1.1/rci/tools/ping')
          .to_return(status: 200, body: '[]')

        expect(diagnostics.ping('8.8.8.8')).to eq({})
      end
    end
  end

  describe '#traceroute' do
    let(:traceroute_response) do
      {
        'host' => 'google.com',
        'hops' => [
          { 'hop' => 1, 'ip' => '192.168.1.1', 'time' => 1, 'hostname' => 'router.local' },
          { 'hop' => 2, 'ip' => '10.0.0.1', 'time' => 5, 'hostname' => 'isp-gateway' },
          { 'hop' => 3, 'ip' => '142.250.185.46', 'time' => 15, 'hostname' => 'google.com' }
        ]
      }
    end

    it 'sends traceroute request' do
      trace_stub = stub_request(:post, 'http://192.168.1.1/rci/tools/traceroute')
        .with(body: { 'host' => 'google.com' }.to_json)
        .to_return(status: 200, body: traceroute_response.to_json)

      result = diagnostics.traceroute('google.com')

      expect(trace_stub).to have_been_requested
      expect(result[:host]).to eq('google.com')
      expect(result[:hops]).to be_an(Array)
      expect(result[:hops].size).to eq(3)
    end

    it 'normalizes hop data' do
      stub_request(:post, 'http://192.168.1.1/rci/tools/traceroute')
        .to_return(status: 200, body: traceroute_response.to_json)

      result = diagnostics.traceroute('google.com')

      expect(result[:hops].first[:hop]).to eq(1)
      expect(result[:hops].first[:ip]).to eq('192.168.1.1')
      expect(result[:hops].first[:time]).to eq(1)
    end

    context 'when response is empty' do
      it 'returns empty hash' do
        stub_request(:post, 'http://192.168.1.1/rci/tools/traceroute')
          .to_return(status: 200, body: '{}')

        expect(diagnostics.traceroute('google.com')).to eq({})
      end
    end

    context 'when response is not a hash' do
      it 'returns empty hash' do
        stub_request(:post, 'http://192.168.1.1/rci/tools/traceroute')
          .to_return(status: 200, body: '[]')

        expect(diagnostics.traceroute('google.com')).to eq({})
      end
    end
  end

  describe '#nslookup' do
    let(:nslookup_response) do
      {
        'host' => 'google.com',
        'addresses' => ['142.250.185.46', '142.250.185.78'],
        'server' => '8.8.8.8',
        'ttl' => 300
      }
    end

    it 'sends nslookup request' do
      lookup_stub = stub_request(:post, 'http://192.168.1.1/rci/tools/nslookup')
        .with(body: { 'host' => 'google.com' }.to_json)
        .to_return(status: 200, body: nslookup_response.to_json)

      result = diagnostics.nslookup('google.com')

      expect(lookup_stub).to have_been_requested
      expect(result[:host]).to eq('google.com')
      expect(result[:addresses]).to eq(['142.250.185.46', '142.250.185.78'])
    end

    it 'includes DNS server info' do
      stub_request(:post, 'http://192.168.1.1/rci/tools/nslookup')
        .to_return(status: 200, body: nslookup_response.to_json)

      result = diagnostics.nslookup('google.com')

      expect(result[:server]).to eq('8.8.8.8')
      expect(result[:ttl]).to eq(300)
    end

    context 'when response is empty' do
      it 'returns empty hash' do
        stub_request(:post, 'http://192.168.1.1/rci/tools/nslookup')
          .to_return(status: 200, body: '{}')

        expect(diagnostics.nslookup('google.com')).to eq({})
      end
    end

    context 'when response is not a hash' do
      it 'returns empty hash' do
        stub_request(:post, 'http://192.168.1.1/rci/tools/nslookup')
          .to_return(status: 200, body: '[]')

        expect(diagnostics.nslookup('google.com')).to eq({})
      end
    end
  end

  describe '#dns_lookup' do
    it 'is an alias for nslookup' do
      lookup_stub = stub_request(:post, 'http://192.168.1.1/rci/tools/nslookup')
        .with(body: { 'host' => 'example.com' }.to_json)
        .to_return(status: 200, body: '{"host": "example.com"}')

      diagnostics.dns_lookup('example.com')

      expect(lookup_stub).to have_been_requested
    end
  end
end
