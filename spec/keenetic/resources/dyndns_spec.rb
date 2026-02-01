require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Dyndns do
  let(:client) { Keenetic::Client.new }
  let(:dyndns) { client.dyndns }

  before { stub_keenetic_auth }

  describe '#keendns_status' do
    let(:keendns_response) do
      {
        'enabled' => true,
        'domain' => 'myrouter',
        'mode' => 'cloud',
        'registered' => true,
        'fqdn' => 'myrouter.keenetic.pro'
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/rc/ip/http/dyndns')
        .to_return(status: 200, body: keendns_response.to_json)
    end

    it 'returns KeenDNS status' do
      result = dyndns.keendns_status

      expect(result).to be_a(Hash)
      expect(result[:enabled]).to eq(true)
      expect(result[:domain]).to eq('myrouter')
    end

    it 'includes registration details' do
      result = dyndns.keendns_status

      expect(result[:registered]).to eq(true)
      expect(result[:fqdn]).to eq('myrouter.keenetic.pro')
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/rc/ip/http/dyndns')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty hash' do
        expect(dyndns.keendns_status).to eq({})
      end
    end
  end

  describe '#configure_keendns' do
    it 'sends configuration request' do
      config_stub = stub_request(:post, 'http://192.168.1.1/rci/ip/http/dyndns')
        .with { |req| JSON.parse(req.body)['enabled'] == true }
        .to_return(status: 200, body: '{}')

      dyndns.configure_keendns(enabled: true, domain: 'myrouter')

      expect(config_stub).to have_been_requested
    end

    it 'converts underscores to dashes in params' do
      config_stub = stub_request(:post, 'http://192.168.1.1/rci/ip/http/dyndns')
        .with { |req| JSON.parse(req.body).key?('some-param') }
        .to_return(status: 200, body: '{}')

      dyndns.configure_keendns(some_param: 'value')

      expect(config_stub).to have_been_requested
    end
  end

  describe '#third_party' do
    let(:ddns_response) do
      {
        'provider' => [
          {
            'name' => 'dyndns',
            'enabled' => true,
            'hostname' => 'myhost.dyndns.org',
            'status' => 'updated'
          },
          {
            'name' => 'noip',
            'enabled' => false,
            'hostname' => '',
            'status' => 'disabled'
          }
        ]
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/dyndns')
        .to_return(status: 200, body: ddns_response.to_json)
    end

    it 'returns third-party DDNS providers' do
      result = dyndns.third_party

      expect(result).to be_a(Hash)
      expect(result[:provider]).to be_an(Array)
      expect(result[:provider].size).to eq(2)
    end

    it 'includes provider details' do
      result = dyndns.third_party

      expect(result[:provider].first[:name]).to eq('dyndns')
      expect(result[:provider].first[:enabled]).to eq(true)
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/dyndns')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty hash' do
        expect(dyndns.third_party).to eq({})
      end
    end
  end

  describe '#providers' do
    it 'is an alias for third_party' do
      stub_request(:get, 'http://192.168.1.1/rci/show/dyndns')
        .to_return(status: 200, body: '{}')

      expect(dyndns.method(:providers)).to eq(dyndns.method(:third_party))
    end
  end
end
