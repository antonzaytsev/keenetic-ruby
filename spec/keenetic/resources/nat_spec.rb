require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Nat do
  let(:client) { Keenetic::Client.new }
  let(:nat) { client.nat }

  before { stub_keenetic_auth }

  describe '#rules' do
    let(:rules_response) do
      [
        {
          'index' => 1,
          'description' => 'Web Server',
          'protocol' => 'tcp',
          'interface' => 'ISP',
          'port' => 8080,
          'end-port' => nil,
          'to-host' => '192.168.1.100',
          'to-port' => 80,
          'enabled' => true
        },
        {
          'index' => 2,
          'description' => 'SSH',
          'protocol' => 'tcp',
          'interface' => 'ISP',
          'port' => 2222,
          'end-port' => nil,
          'to-host' => '192.168.1.101',
          'to-port' => 22,
          'enabled' => false
        }
      ]
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/ip/nat')
        .to_return(status: 200, body: rules_response.to_json)
    end

    it 'returns normalized list of NAT rules' do
      result = nat.rules

      expect(result.size).to eq(2)
      expect(result.first[:index]).to eq(1)
      expect(result.first[:description]).to eq('Web Server')
      expect(result.first[:protocol]).to eq('tcp')
      expect(result.first[:interface]).to eq('ISP')
      expect(result.first[:port]).to eq(8080)
      expect(result.first[:to_host]).to eq('192.168.1.100')
      expect(result.first[:to_port]).to eq(80)
      expect(result.first[:enabled]).to eq(true)
    end

    it 'normalizes boolean enabled field' do
      result = nat.rules

      expect(result.first[:enabled]).to eq(true)
      expect(result.last[:enabled]).to eq(false)
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ip/nat')
          .to_return(status: 200, body: '[]')
      end

      it 'returns empty array' do
        expect(nat.rules).to eq([])
      end
    end

    context 'when response is not an array' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/ip/nat')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty array' do
        expect(nat.rules).to eq([])
      end
    end

    context 'with port range' do
      let(:rules_response) do
        [
          {
            'index' => 1,
            'description' => 'Game Ports',
            'protocol' => 'udp',
            'interface' => 'ISP',
            'port' => 27015,
            'end-port' => 27030,
            'to-host' => '192.168.1.50',
            'to-port' => 27015,
            'enabled' => true
          }
        ]
      end

      it 'includes end_port for port ranges' do
        result = nat.rules

        expect(result.first[:port]).to eq(27015)
        expect(result.first[:end_port]).to eq(27030)
      end
    end
  end

  describe '#find_rule' do
    let(:rules_response) do
      [
        {
          'index' => 1,
          'description' => 'Web Server',
          'protocol' => 'tcp',
          'interface' => 'ISP',
          'port' => 8080,
          'to-host' => '192.168.1.100',
          'to-port' => 80,
          'enabled' => true
        },
        {
          'index' => 2,
          'description' => 'SSH',
          'protocol' => 'tcp',
          'interface' => 'ISP',
          'port' => 2222,
          'to-host' => '192.168.1.101',
          'to-port' => 22,
          'enabled' => true
        }
      ]
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/ip/nat')
        .to_return(status: 200, body: rules_response.to_json)
    end

    it 'finds rule by index' do
      result = nat.find_rule(1)

      expect(result[:index]).to eq(1)
      expect(result[:description]).to eq('Web Server')
    end

    it 'returns nil for unknown index' do
      expect(nat.find_rule(999)).to be_nil
    end
  end

  describe '#add_forward' do
    it 'sends port forward rule with all parameters' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/ip/nat')
        .with { |request|
          body = JSON.parse(request.body)
          body['index'] == 1 &&
            body['description'] == 'Web Server' &&
            body['protocol'] == 'tcp' &&
            body['interface'] == 'ISP' &&
            body['port'] == 8080 &&
            body['to-host'] == '192.168.1.100' &&
            body['to-port'] == 80 &&
            body['enabled'] == true
        }
        .to_return(status: 200, body: '{}')

      nat.add_forward(
        index: 1,
        description: 'Web Server',
        protocol: 'tcp',
        port: 8080,
        to_host: '192.168.1.100',
        to_port: 80
      )

      expect(add_stub).to have_been_requested
    end

    it 'sends port forward without optional description' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/ip/nat')
        .with { |request|
          body = JSON.parse(request.body)
          body['index'] == 1 &&
            body['protocol'] == 'tcp' &&
            body['interface'] == 'ISP' &&
            body['port'] == 22 &&
            body['to-host'] == '192.168.1.50' &&
            body['to-port'] == 22 &&
            body['enabled'] == true &&
            !body.key?('description')
        }
        .to_return(status: 200, body: '{}')

      nat.add_forward(
        index: 1,
        protocol: 'tcp',
        port: 22,
        to_host: '192.168.1.50',
        to_port: 22
      )

      expect(add_stub).to have_been_requested
    end

    it 'sends port range forward with end_port' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/ip/nat')
        .with { |request|
          body = JSON.parse(request.body)
          body['index'] == 2 &&
            body['description'] == 'Game Ports' &&
            body['protocol'] == 'udp' &&
            body['interface'] == 'ISP' &&
            body['port'] == 27015 &&
            body['end-port'] == 27030 &&
            body['to-host'] == '192.168.1.50' &&
            body['to-port'] == 27015 &&
            body['enabled'] == true
        }
        .to_return(status: 200, body: '{}')

      nat.add_forward(
        index: 2,
        description: 'Game Ports',
        protocol: 'udp',
        port: 27015,
        end_port: 27030,
        to_host: '192.168.1.50',
        to_port: 27015
      )

      expect(add_stub).to have_been_requested
    end

    it 'allows specifying custom interface' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/ip/nat')
        .with(body: {
          'index' => 1,
          'protocol' => 'tcp',
          'interface' => 'PPPoE0',
          'port' => 80,
          'to-host' => '192.168.1.100',
          'to-port' => 80,
          'enabled' => true
        }.to_json)
        .to_return(status: 200, body: '{}')

      nat.add_forward(
        index: 1,
        protocol: 'tcp',
        interface: 'PPPoE0',
        port: 80,
        to_host: '192.168.1.100',
        to_port: 80
      )

      expect(add_stub).to have_been_requested
    end

    it 'allows disabling the rule on creation' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/ip/nat')
        .with(body: {
          'index' => 1,
          'protocol' => 'tcp',
          'interface' => 'ISP',
          'port' => 80,
          'to-host' => '192.168.1.100',
          'to-port' => 80,
          'enabled' => false
        }.to_json)
        .to_return(status: 200, body: '{}')

      nat.add_forward(
        index: 1,
        protocol: 'tcp',
        port: 80,
        to_host: '192.168.1.100',
        to_port: 80,
        enabled: false
      )

      expect(add_stub).to have_been_requested
    end
  end

  describe '#delete_forward' do
    it 'sends delete command with rule index' do
      delete_stub = stub_request(:post, 'http://192.168.1.1/rci/ip/nat')
        .with(body: {
          'index' => 1,
          'no' => true
        }.to_json)
        .to_return(status: 200, body: '{}')

      nat.delete_forward(index: 1)

      expect(delete_stub).to have_been_requested
    end

    it 'works with different index values' do
      delete_stub = stub_request(:post, 'http://192.168.1.1/rci/ip/nat')
        .with(body: {
          'index' => 99,
          'no' => true
        }.to_json)
        .to_return(status: 200, body: '{}')

      nat.delete_forward(index: 99)

      expect(delete_stub).to have_been_requested
    end
  end
end
