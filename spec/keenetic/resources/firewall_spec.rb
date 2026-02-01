require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Firewall do
  let(:client) { Keenetic::Client.new }
  let(:firewall) { client.firewall }

  before { stub_keenetic_auth }

  describe '#policies' do
    let(:policies_response) do
      {
        'policy' => [
          {
            'index' => 1,
            'action' => 'permit',
            'protocol' => 'tcp',
            'src-address' => '192.168.1.0/24',
            'dst-port' => 80,
            'enabled' => true
          },
          {
            'index' => 2,
            'action' => 'deny',
            'protocol' => 'any',
            'src-address' => '10.0.0.0/8',
            'enabled' => true
          }
        ],
        'default-action' => 'permit'
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/ip/policy')
        .to_return(status: 200, body: policies_response.to_json)
    end

    it 'returns firewall policies' do
      result = firewall.policies

      expect(result[:policy]).to be_an(Array)
      expect(result[:policy].size).to eq(2)
      expect(result[:default_action]).to eq('permit')
    end

    it 'normalizes kebab-case keys' do
      result = firewall.policies

      expect(result[:policy].first[:src_address]).to eq('192.168.1.0/24')
      expect(result[:policy].first[:dst_port]).to eq(80)
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ip/policy')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty hash' do
        expect(firewall.policies).to eq({})
      end
    end

    context 'when response is not a hash' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ip/policy')
          .to_return(status: 200, body: '[]')
      end

      it 'returns empty hash' do
        expect(firewall.policies).to eq({})
      end
    end
  end

  describe '#access_lists' do
    let(:access_lists_response) do
      {
        'access-list' => [
          {
            'name' => 'LAN-access',
            'permit' => ['192.168.1.0/24'],
            'deny' => ['10.0.0.0/8']
          },
          {
            'name' => 'WAN-block',
            'deny' => ['0.0.0.0/0']
          }
        ]
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/access-list')
        .to_return(status: 200, body: access_lists_response.to_json)
    end

    it 'returns access lists' do
      result = firewall.access_lists

      expect(result[:access_list]).to be_an(Array)
      expect(result[:access_list].size).to eq(2)
    end

    it 'normalizes access list data' do
      result = firewall.access_lists

      expect(result[:access_list].first[:name]).to eq('LAN-access')
      expect(result[:access_list].first[:permit]).to eq(['192.168.1.0/24'])
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/access-list')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty hash' do
        expect(firewall.access_lists).to eq({})
      end
    end

    context 'when response is not a hash' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/access-list')
          .to_return(status: 200, body: '[]')
      end

      it 'returns empty hash' do
        expect(firewall.access_lists).to eq({})
      end
    end
  end

  describe '#add_rule' do
    it 'sends rule with all parameters' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/ip/policy')
        .with { |request|
          body = JSON.parse(request.body)
          body['action'] == 'permit' &&
            body['protocol'] == 'tcp' &&
            body['src-address'] == '192.168.1.0/24' &&
            body['dst-port'] == 80
        }
        .to_return(status: 200, body: '{}')

      firewall.add_rule(
        action: 'permit',
        protocol: 'tcp',
        src_address: '192.168.1.0/24',
        dst_port: 80
      )

      expect(add_stub).to have_been_requested
    end

    it 'converts snake_case params to kebab-case' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/ip/policy')
        .with { |request|
          body = JSON.parse(request.body)
          body.key?('src-address') && body.key?('dst-port')
        }
        .to_return(status: 200, body: '{}')

      firewall.add_rule(src_address: '10.0.0.0/8', dst_port: 443)

      expect(add_stub).to have_been_requested
    end

    it 'sends deny rule' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/ip/policy')
        .with { |request|
          body = JSON.parse(request.body)
          body['action'] == 'deny' && body['protocol'] == 'any'
        }
        .to_return(status: 200, body: '{}')

      firewall.add_rule(action: 'deny', protocol: 'any')

      expect(add_stub).to have_been_requested
    end
  end

  describe '#delete_rule' do
    it 'sends delete command with rule index' do
      delete_stub = stub_request(:post, 'http://192.168.1.1/rci/ip/policy')
        .with(body: { 'index' => 1, 'no' => true }.to_json)
        .to_return(status: 200, body: '{}')

      firewall.delete_rule(index: 1)

      expect(delete_stub).to have_been_requested
    end

    it 'works with different index values' do
      delete_stub = stub_request(:post, 'http://192.168.1.1/rci/ip/policy')
        .with(body: { 'index' => 99, 'no' => true }.to_json)
        .to_return(status: 200, body: '{}')

      firewall.delete_rule(index: 99)

      expect(delete_stub).to have_been_requested
    end
  end
end
