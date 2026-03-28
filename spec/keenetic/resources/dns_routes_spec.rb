require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::DnsRoutes do
  let(:client) { Keenetic::Client.new }
  let(:dns_routes) { client.dns_routes }

  before { stub_keenetic_auth }

  let(:fqdn_response) do
    [
      {
        'show' => {
          'sc' => {
            'object-group' => {
              'fqdn' => {
                'domain-list0' => {
                  'description' => 'youtube.com',
                  'include' => [
                    { 'address' => 'googlevideo.com' },
                    { 'address' => 'youtube.com' },
                    { 'address' => 'ytimg.com' }
                  ]
                },
                'domain-list1' => {
                  'description' => 'telegram',
                  'include' => [
                    { 'address' => 'telegram.org' },
                    { 'address' => 'api.telegram.org' }
                  ]
                }
              }
            }
          }
        }
      }
    ]
  end

  let(:routes_response) do
    [
      {
        'show' => {
          'sc' => {
            'dns-proxy' => {
              'route' => [
                {
                  'group' => 'domain-list0',
                  'interface' => 'Wireguard2',
                  'auto' => true,
                  'index' => 'c52bba355a2830fdf55ccb3748a879df',
                  'comment' => ''
                },
                {
                  'group' => 'domain-list1',
                  'interface' => 'Wireguard0',
                  'auto' => true,
                  'index' => 'f5061eb124f54cc42be95410b1b36917',
                  'comment' => 'my route'
                }
              ]
            }
          }
        }
      }
    ]
  end

  describe '#domain_groups' do
    before do
      stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [{ 'show' => { 'sc' => { 'object-group' => { 'fqdn' => {} } } } }].to_json)
        .to_return(status: 200, body: fqdn_response.to_json)
    end

    it 'returns normalized list of domain groups' do
      result = dns_routes.domain_groups

      expect(result.size).to eq(2)
    end

    it 'normalizes group name and description' do
      result = dns_routes.domain_groups

      expect(result.first[:name]).to eq('domain-list0')
      expect(result.first[:description]).to eq('youtube.com')
    end

    it 'extracts domain list from include array' do
      result = dns_routes.domain_groups

      expect(result.first[:domains]).to eq(['googlevideo.com', 'youtube.com', 'ytimg.com'])
    end

    it 'handles multiple groups' do
      result = dns_routes.domain_groups

      expect(result.last[:name]).to eq('domain-list1')
      expect(result.last[:domains]).to eq(['telegram.org', 'api.telegram.org'])
    end

    context 'when response is empty' do
      before do
        stub_request(:post, 'http://192.168.1.1/rci/')
          .with(body: [{ 'show' => { 'sc' => { 'object-group' => { 'fqdn' => {} } } } }].to_json)
          .to_return(status: 200, body: [{ 'show' => { 'sc' => { 'object-group' => { 'fqdn' => {} } } } }].to_json)
      end

      it 'returns empty array' do
        expect(dns_routes.domain_groups).to eq([])
      end
    end
  end

  describe '#find_domain_group' do
    before do
      stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [{ 'show' => { 'sc' => { 'object-group' => { 'fqdn' => {} } } } }].to_json)
        .to_return(status: 200, body: fqdn_response.to_json)
    end

    it 'returns the matching group' do
      result = dns_routes.find_domain_group(name: 'domain-list0')

      expect(result[:name]).to eq('domain-list0')
      expect(result[:description]).to eq('youtube.com')
    end

    it 'returns nil when group does not exist' do
      result = dns_routes.find_domain_group(name: 'nonexistent')

      expect(result).to be_nil
    end
  end

  describe '#create_domain_group' do
    let(:expected_body) do
      [
        { 'webhelp' => { 'event' => { 'push' => { 'data' => '{"type":"configuration_change","value":{"url":"/staticRoutes/dns"}}' } } } },
        { 'object-group' => { 'fqdn' => { 'domain-list2' => { 'description' => 'My Domains', 'include' => [{ 'address' => 'example.com' }, { 'address' => 'example.org' }] } } } },
        { 'system' => { 'configuration' => { 'save' => {} } } }
      ]
    end

    before do
      stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: expected_body.to_json)
        .to_return(status: 200, body: [{}].to_json)
    end

    it 'sends the correct batch command' do
      stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: expected_body.to_json)
        .to_return(status: 200, body: [{}].to_json)

      dns_routes.create_domain_group(
        name: 'domain-list2',
        description: 'My Domains',
        domains: ['example.com', 'example.org']
      )

      expect(stub).to have_been_requested
    end

    it 'raises ArgumentError when name is missing' do
      expect do
        dns_routes.create_domain_group(name: '', description: 'Test', domains: ['example.com'])
      end.to raise_error(ArgumentError, /Name is required/)
    end

    it 'raises ArgumentError when description is missing' do
      expect do
        dns_routes.create_domain_group(name: 'domain-list2', description: '', domains: ['example.com'])
      end.to raise_error(ArgumentError, /Description is required/)
    end

    it 'raises ArgumentError when domains is empty' do
      expect do
        dns_routes.create_domain_group(name: 'domain-list2', description: 'Test', domains: [])
      end.to raise_error(ArgumentError, /Domains cannot be empty/)
    end
  end

  describe '#delete_domain_group' do
    let(:expected_body) do
      [
        { 'webhelp' => { 'event' => { 'push' => { 'data' => '{"type":"configuration_change","value":{"url":"/staticRoutes/dns"}}' } } } },
        { 'object-group' => { 'fqdn' => { 'domain-list0' => { 'no' => true } } } },
        { 'system' => { 'configuration' => { 'save' => {} } } }
      ]
    end

    it 'sends the correct delete command' do
      stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: expected_body.to_json)
        .to_return(status: 200, body: [{}].to_json)

      dns_routes.delete_domain_group(name: 'domain-list0')

      expect(stub).to have_been_requested
    end

    it 'raises ArgumentError when name is missing' do
      expect do
        dns_routes.delete_domain_group(name: '')
      end.to raise_error(ArgumentError, /Name is required/)
    end
  end

  describe '#routes' do
    before do
      stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [{ 'show' => { 'sc' => { 'dns-proxy' => { 'route' => {} } } } }].to_json)
        .to_return(status: 200, body: routes_response.to_json)
    end

    it 'returns normalized list of DNS-based routes' do
      result = dns_routes.routes

      expect(result.size).to eq(2)
    end

    it 'normalizes route fields' do
      result = dns_routes.routes

      expect(result.first[:group]).to eq('domain-list0')
      expect(result.first[:interface]).to eq('Wireguard2')
      expect(result.first[:auto]).to eq(true)
      expect(result.first[:index]).to eq('c52bba355a2830fdf55ccb3748a879df')
      expect(result.first[:comment]).to eq('')
    end

    it 'normalizes comment field' do
      result = dns_routes.routes

      expect(result.last[:comment]).to eq('my route')
    end

    context 'when response has no routes' do
      before do
        stub_request(:post, 'http://192.168.1.1/rci/')
          .with(body: [{ 'show' => { 'sc' => { 'dns-proxy' => { 'route' => {} } } } }].to_json)
          .to_return(status: 200, body: [{ 'show' => { 'sc' => { 'dns-proxy' => { 'route' => [] } } } }].to_json)
      end

      it 'returns empty array' do
        expect(dns_routes.routes).to eq([])
      end
    end
  end

  describe '#find_route' do
    before do
      stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [{ 'show' => { 'sc' => { 'dns-proxy' => { 'route' => {} } } } }].to_json)
        .to_return(status: 200, body: routes_response.to_json)
    end

    it 'returns the matching route' do
      result = dns_routes.find_route(group: 'domain-list0')

      expect(result[:group]).to eq('domain-list0')
      expect(result[:interface]).to eq('Wireguard2')
    end

    it 'returns nil when route does not exist' do
      result = dns_routes.find_route(group: 'nonexistent')

      expect(result).to be_nil
    end
  end

  describe '#add_route' do
    let(:expected_body) do
      [
        { 'webhelp' => { 'event' => { 'push' => { 'data' => '{"type":"configuration_change","value":{"url":"/staticRoutes/dns"}}' } } } },
        { 'dns-proxy' => { 'route' => { 'group' => 'domain-list0', 'interface' => 'Wireguard0', 'auto' => true, 'comment' => '' } } },
        { 'system' => { 'configuration' => { 'save' => {} } } }
      ]
    end

    it 'sends the correct create command with auto:true' do
      stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: expected_body.to_json)
        .to_return(status: 200, body: [{}].to_json)

      dns_routes.add_route(group: 'domain-list0', interface: 'Wireguard0')

      expect(stub).to have_been_requested
    end

    it 'includes comment when provided' do
      expected_with_comment = [
        { 'webhelp' => { 'event' => { 'push' => { 'data' => '{"type":"configuration_change","value":{"url":"/staticRoutes/dns"}}' } } } },
        { 'dns-proxy' => { 'route' => { 'group' => 'domain-list0', 'interface' => 'Wireguard0', 'auto' => true, 'comment' => 'my comment' } } },
        { 'system' => { 'configuration' => { 'save' => {} } } }
      ]

      stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: expected_with_comment.to_json)
        .to_return(status: 200, body: [{}].to_json)

      dns_routes.add_route(group: 'domain-list0', interface: 'Wireguard0', comment: 'my comment')

      expect(stub).to have_been_requested
    end

    it 'raises ArgumentError when group is missing' do
      expect do
        dns_routes.add_route(group: '', interface: 'Wireguard0')
      end.to raise_error(ArgumentError, /Group is required/)
    end

    it 'raises ArgumentError when interface is missing' do
      expect do
        dns_routes.add_route(group: 'domain-list0', interface: '')
      end.to raise_error(ArgumentError, /Interface is required/)
    end
  end

  describe '#delete_route' do
    let(:expected_body) do
      [
        { 'webhelp' => { 'event' => { 'push' => { 'data' => '{"type":"configuration_change","value":{"url":"/staticRoutes/dns"}}' } } } },
        { 'dns-proxy' => { 'route' => { 'no' => true, 'index' => 'c52bba355a2830fdf55ccb3748a879df' } } },
        { 'system' => { 'configuration' => { 'save' => {} } } }
      ]
    end

    it 'sends the correct delete command' do
      stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: expected_body.to_json)
        .to_return(status: 200, body: [{}].to_json)

      dns_routes.delete_route(index: 'c52bba355a2830fdf55ccb3748a879df')

      expect(stub).to have_been_requested
    end

    it 'raises ArgumentError when index is missing' do
      expect do
        dns_routes.delete_route(index: '')
      end.to raise_error(ArgumentError, /Index is required/)
    end
  end
end
