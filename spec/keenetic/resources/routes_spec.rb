require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Routes do
  let(:client) { Keenetic::Client.new }
  let(:routes) { client.routes }

  before { stub_keenetic_auth }

  describe '.cidr_to_mask' do
    it 'converts common CIDR prefixes to masks' do
      expect(described_class.cidr_to_mask(8)).to eq('255.0.0.0')
      expect(described_class.cidr_to_mask(16)).to eq('255.255.0.0')
      expect(described_class.cidr_to_mask(24)).to eq('255.255.255.0')
      expect(described_class.cidr_to_mask(32)).to eq('255.255.255.255')
    end

    it 'converts less common CIDR prefixes' do
      expect(described_class.cidr_to_mask(17)).to eq('255.255.128.0')
      expect(described_class.cidr_to_mask(25)).to eq('255.255.255.128')
      expect(described_class.cidr_to_mask(30)).to eq('255.255.255.252')
    end

    it 'accepts string input' do
      expect(described_class.cidr_to_mask('24')).to eq('255.255.255.0')
    end

    it 'raises ArgumentError for invalid CIDR' do
      expect { described_class.cidr_to_mask(0) }.to raise_error(ArgumentError)
      expect { described_class.cidr_to_mask(33) }.to raise_error(ArgumentError)
      expect { described_class.cidr_to_mask('invalid') }.to raise_error(ArgumentError)
    end
  end

  describe '#all' do
    let(:routes_response) do
      [
        {
          'show' => {
            'sc' => {
              'ip' => {
                'route' => [
                  {
                    'network' => '10.0.0.0',
                    'mask' => '255.255.255.0',
                    'interface' => 'Wireguard0',
                    'gateway' => '',
                    'auto' => true,
                    'reject' => false,
                    'comment' => 'VPN route'
                  },
                  {
                    'host' => '1.2.3.4',
                    'interface' => 'Wireguard0',
                    'gateway' => '',
                    'auto' => true,
                    'reject' => false,
                    'comment' => 'Single host'
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
        .with(body: [{ 'show' => { 'sc' => { 'ip' => { 'route' => {} } } } }].to_json)
        .to_return(status: 200, body: routes_response.to_json)
    end

    it 'returns normalized list of static routes' do
      result = routes.all

      expect(result.size).to eq(2)
      expect(result.first[:network]).to eq('10.0.0.0')
      expect(result.first[:mask]).to eq('255.255.255.0')
      expect(result.first[:interface]).to eq('Wireguard0')
      expect(result.first[:auto]).to eq(true)
      expect(result.first[:reject]).to eq(false)
      expect(result.first[:comment]).to eq('VPN route')
    end

    it 'returns host routes' do
      result = routes.all

      expect(result.last[:host]).to eq('1.2.3.4')
      expect(result.last[:network]).to be_nil
    end

    context 'when response is empty' do
      before do
        stub_request(:post, 'http://192.168.1.1/rci/')
          .with(body: [{ 'show' => { 'sc' => { 'ip' => { 'route' => {} } } } }].to_json)
          .to_return(status: 200, body: [{ 'show' => { 'sc' => { 'ip' => { 'route' => [] } } } }].to_json)
      end

      it 'returns empty array' do
        expect(routes.all).to eq([])
      end
    end
  end

  describe '#add' do
    it 'sends add command for host route' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .to_return(status: 200, body: '[{}, {}, {}]')

      routes.add(host: '1.2.3.4', interface: 'Wireguard0', comment: 'Test route')

      expect(add_stub).to have_been_requested
      expect(WebMock).to have_requested(:post, 'http://192.168.1.1/rci/').with { |req|
        body = JSON.parse(req.body)
        body[1]['ip']['route']['host'] == '1.2.3.4' &&
          body[1]['ip']['route']['interface'] == 'Wireguard0' &&
          body[1]['ip']['route']['comment'] == 'Test route'
      }
    end

    it 'sends add command for network route with explicit mask' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .to_return(status: 200, body: '[{}, {}, {}]')

      routes.add(network: '10.0.0.0', mask: '255.255.255.0', interface: 'Wireguard0', comment: 'Network route')

      expect(add_stub).to have_been_requested
      expect(WebMock).to have_requested(:post, 'http://192.168.1.1/rci/').with { |req|
        body = JSON.parse(req.body)
        body[1]['ip']['route']['network'] == '10.0.0.0' &&
          body[1]['ip']['route']['mask'] == '255.255.255.0' &&
          body[1]['ip']['route']['interface'] == 'Wireguard0'
      }
    end

    it 'converts CIDR notation for network routes' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .to_return(status: 200, body: '[{}, {}, {}]')

      routes.add(network: '10.0.0.0/24', interface: 'Wireguard0', comment: 'CIDR route')

      expect(add_stub).to have_been_requested
      expect(WebMock).to have_requested(:post, 'http://192.168.1.1/rci/').with { |req|
        body = JSON.parse(req.body)
        body[1]['ip']['route']['network'] == '10.0.0.0' &&
          body[1]['ip']['route']['mask'] == '255.255.255.0'
      }
    end

    it 'converts host with CIDR /32 to host route' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .to_return(status: 200, body: '[{}, {}, {}]')

      routes.add(host: '1.2.3.4/32', interface: 'Wireguard0', comment: 'Host route')

      expect(add_stub).to have_been_requested
      expect(WebMock).to have_requested(:post, 'http://192.168.1.1/rci/').with { |req|
        body = JSON.parse(req.body)
        body[1]['ip']['route']['host'] == '1.2.3.4' &&
          body[1]['ip']['route']['network'].nil?
      }
    end

    it 'converts host with non-32 CIDR to network route' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .to_return(status: 200, body: '[{}, {}, {}]')

      routes.add(host: '10.0.0.0/24', interface: 'Wireguard0', comment: 'Network from host')

      expect(add_stub).to have_been_requested
      expect(WebMock).to have_requested(:post, 'http://192.168.1.1/rci/').with { |req|
        body = JSON.parse(req.body)
        body[1]['ip']['route']['network'] == '10.0.0.0' &&
          body[1]['ip']['route']['mask'] == '255.255.255.0' &&
          body[1]['ip']['route']['host'].nil?
      }
    end

    it 'includes gateway when provided' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .to_return(status: 200, body: '[{}, {}, {}]')

      routes.add(host: '1.2.3.4', interface: 'Wireguard0', comment: 'With gateway', gateway: '192.168.1.1')

      expect(add_stub).to have_been_requested
      expect(WebMock).to have_requested(:post, 'http://192.168.1.1/rci/').with { |req|
        body = JSON.parse(req.body)
        body[1]['ip']['route']['gateway'] == '192.168.1.1'
      }
    end

    it 'raises ArgumentError when interface is missing' do
      expect { routes.add(host: '1.2.3.4', interface: nil, comment: 'Test') }.to raise_error(ArgumentError, /Interface is required/)
      expect { routes.add(host: '1.2.3.4', interface: '', comment: 'Test') }.to raise_error(ArgumentError, /Interface is required/)
    end

    it 'raises ArgumentError when comment is missing' do
      expect { routes.add(host: '1.2.3.4', interface: 'Wireguard0', comment: nil) }.to raise_error(ArgumentError, /Comment is required/)
      expect { routes.add(host: '1.2.3.4', interface: 'Wireguard0', comment: '') }.to raise_error(ArgumentError, /Comment is required/)
    end

    it 'raises ArgumentError when neither host nor network is provided' do
      expect { routes.add(interface: 'Wireguard0', comment: 'Test') }.to raise_error(ArgumentError, /Either host or network/)
    end

    it 'raises ArgumentError when network without mask or CIDR' do
      expect { routes.add(network: '10.0.0.0', interface: 'Wireguard0', comment: 'Test') }.to raise_error(ArgumentError, /Mask is required/)
    end
  end

  describe '#add_batch' do
    it 'sends batch add commands for multiple routes' do
      add_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .to_return(status: 200, body: '[{}, {}, {}, {}]')

      routes.add_batch([
        { host: '1.2.3.4', interface: 'Wireguard0', comment: 'Host 1' },
        { network: '10.0.0.0/24', interface: 'Wireguard0', comment: 'Network 1' }
      ])

      expect(add_stub).to have_been_requested
      expect(WebMock).to have_requested(:post, 'http://192.168.1.1/rci/').with { |req|
        body = JSON.parse(req.body)
        body.size == 4 &&
          !body[0]['webhelp'].nil? &&
          body[1]['ip']['route']['host'] == '1.2.3.4' &&
          body[2]['ip']['route']['network'] == '10.0.0.0' &&
          body[2]['ip']['route']['mask'] == '255.255.255.0' &&
          !body[3]['system']['configuration']['save'].nil?
      }
    end

    it 'raises ArgumentError when routes array is empty' do
      expect { routes.add_batch([]) }.to raise_error(ArgumentError, /cannot be empty/)
      expect { routes.add_batch(nil) }.to raise_error(ArgumentError, /cannot be empty/)
    end
  end

  describe '#delete' do
    it 'sends delete command for host route' do
      delete_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [
          { 'webhelp' => { 'event' => { 'push' => { 'data' => '{"type":"configuration_change","value":{"url":"/staticRoutes"}}' } } } },
          { 'ip' => { 'route' => { 'no' => true, 'host' => '1.2.3.4' } } },
          { 'system' => { 'configuration' => { 'save' => {} } } }
        ].to_json)
        .to_return(status: 200, body: '[{}, {}, {}]')

      routes.delete(host: '1.2.3.4')

      expect(delete_stub).to have_been_requested
    end

    it 'sends delete command for network route with explicit mask' do
      delete_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [
          { 'webhelp' => { 'event' => { 'push' => { 'data' => '{"type":"configuration_change","value":{"url":"/staticRoutes"}}' } } } },
          { 'ip' => { 'route' => { 'no' => true, 'network' => '10.0.0.0', 'mask' => '255.255.255.0' } } },
          { 'system' => { 'configuration' => { 'save' => {} } } }
        ].to_json)
        .to_return(status: 200, body: '[{}, {}, {}]')

      routes.delete(network: '10.0.0.0', mask: '255.255.255.0')

      expect(delete_stub).to have_been_requested
    end

    it 'converts CIDR notation for delete' do
      delete_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [
          { 'webhelp' => { 'event' => { 'push' => { 'data' => '{"type":"configuration_change","value":{"url":"/staticRoutes"}}' } } } },
          { 'ip' => { 'route' => { 'no' => true, 'network' => '10.0.0.0', 'mask' => '255.255.255.0' } } },
          { 'system' => { 'configuration' => { 'save' => {} } } }
        ].to_json)
        .to_return(status: 200, body: '[{}, {}, {}]')

      routes.delete(network: '10.0.0.0/24')

      expect(delete_stub).to have_been_requested
    end

    it 'raises ArgumentError when neither host nor network is provided' do
      expect { routes.delete }.to raise_error(ArgumentError, /Either host or network/)
    end
  end

  describe '#delete_batch' do
    it 'sends batch delete commands for multiple routes' do
      delete_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [
          { 'webhelp' => { 'event' => { 'push' => { 'data' => '{"type":"configuration_change","value":{"url":"/staticRoutes"}}' } } } },
          { 'ip' => { 'route' => { 'no' => true, 'host' => '1.2.3.4' } } },
          { 'ip' => { 'route' => { 'no' => true, 'network' => '10.0.0.0', 'mask' => '255.255.255.0' } } },
          { 'system' => { 'configuration' => { 'save' => {} } } }
        ].to_json)
        .to_return(status: 200, body: '[{}, {}, {}, {}]')

      routes.delete_batch([
        { host: '1.2.3.4' },
        { network: '10.0.0.0/24' }
      ])

      expect(delete_stub).to have_been_requested
    end

    it 'raises ArgumentError when routes array is empty' do
      expect { routes.delete_batch([]) }.to raise_error(ArgumentError, /cannot be empty/)
      expect { routes.delete_batch(nil) }.to raise_error(ArgumentError, /cannot be empty/)
    end
  end
end
