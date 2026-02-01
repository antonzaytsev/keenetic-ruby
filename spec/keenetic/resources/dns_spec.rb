require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Dns do
  let(:client) { Keenetic::Client.new }
  let(:dns) { client.dns }

  before { stub_keenetic_auth }

  describe '#servers' do
    let(:servers_response) do
      {
        'server' => [
          { 'address' => '8.8.8.8', 'interface' => 'ISP' },
          { 'address' => '8.8.4.4', 'interface' => 'ISP' }
        ],
        'default' => '8.8.8.8'
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/ip/name-server')
        .to_return(status: 200, body: servers_response.to_json)
    end

    it 'returns DNS servers configuration' do
      result = dns.servers

      expect(result).to be_a(Hash)
      expect(result[:server]).to be_an(Array)
      expect(result[:default]).to eq('8.8.8.8')
    end

    it 'normalizes server data' do
      result = dns.servers

      expect(result[:server].first[:address]).to eq('8.8.8.8')
      expect(result[:server].first[:interface]).to eq('ISP')
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ip/name-server')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty hash' do
        expect(dns.servers).to eq({})
      end
    end

    context 'when response is not a hash' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ip/name-server')
          .to_return(status: 200, body: '"invalid"')
      end

      it 'returns empty hash' do
        expect(dns.servers).to eq({})
      end
    end
  end

  describe '#name_servers' do
    it 'is an alias for servers' do
      stub_request(:get, 'http://192.168.1.1/rci/show/ip/name-server')
        .to_return(status: 200, body: '{}')

      expect(dns.method(:name_servers)).to eq(dns.method(:servers))
    end
  end

  describe '#cache' do
    let(:cache_response) do
      {
        'entries' => [
          {
            'name' => 'example.com',
            'type' => 'A',
            'ttl' => 300,
            'address' => '93.184.216.34'
          },
          {
            'name' => 'google.com',
            'type' => 'A',
            'ttl' => 120,
            'address' => '142.250.185.46'
          }
        ],
        'size' => 2
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/dns/cache')
        .to_return(status: 200, body: cache_response.to_json)
    end

    it 'returns DNS cache entries' do
      result = dns.cache

      expect(result).to be_a(Hash)
      expect(result[:entries]).to be_an(Array)
      expect(result[:size]).to eq(2)
    end

    it 'normalizes cache entry data' do
      result = dns.cache

      expect(result[:entries].first[:name]).to eq('example.com')
      expect(result[:entries].first[:type]).to eq('A')
      expect(result[:entries].first[:ttl]).to eq(300)
    end

    context 'when cache is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/dns/cache')
          .to_return(status: 200, body: '{"entries": [], "size": 0}')
      end

      it 'returns empty entries' do
        result = dns.cache

        expect(result[:entries]).to eq([])
        expect(result[:size]).to eq(0)
      end
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/dns/cache')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty hash' do
        expect(dns.cache).to eq({})
      end
    end
  end

  describe '#proxy' do
    let(:proxy_response) do
      {
        'enabled' => true,
        'bind-address' => '192.168.1.1',
        'port' => 53,
        'filter' => true
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/dns/proxy')
        .to_return(status: 200, body: proxy_response.to_json)
    end

    it 'returns DNS proxy settings' do
      result = dns.proxy

      expect(result).to be_a(Hash)
      expect(result[:enabled]).to eq(true)
      expect(result[:port]).to eq(53)
    end

    it 'normalizes kebab-case keys' do
      result = dns.proxy

      expect(result[:bind_address]).to eq('192.168.1.1')
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/dns/proxy')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty hash' do
        expect(dns.proxy).to eq({})
      end
    end
  end

  describe '#proxy_settings' do
    it 'is an alias for proxy' do
      stub_request(:get, 'http://192.168.1.1/rci/show/dns/proxy')
        .to_return(status: 200, body: '{}')

      expect(dns.method(:proxy_settings)).to eq(dns.method(:proxy))
    end
  end

  describe '#clear_cache' do
    it 'sends clear cache command' do
      clear_stub = stub_request(:post, 'http://192.168.1.1/rci/dns/cache/clear')
        .with(body: '{}')
        .to_return(status: 200, body: '{}')

      dns.clear_cache

      expect(clear_stub).to have_been_requested
    end
  end
end
