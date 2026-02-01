require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Config do
  let(:client) { Keenetic::Client.new }
  let(:config_resource) { client.system_config }

  before { stub_keenetic_auth }

  describe '#save' do
    it 'sends save configuration command' do
      save_stub = stub_request(:post, 'http://192.168.1.1/rci/')
        .with(body: [{ 'system' => { 'configuration' => { 'save' => {} } } }].to_json)
        .to_return(status: 200, body: [{ 'system' => { 'configuration' => { 'save' => {} } } }].to_json)

      config_resource.save

      expect(save_stub).to have_been_requested
    end
  end

  describe '#download' do
    let(:config_content) do
      <<~CONFIG
        ! Router configuration
        system name-server 8.8.8.8
        interface Bridge0
          ip address 192.168.1.1/24
      CONFIG
    end

    before do
      stub_request(:get, 'http://192.168.1.1/ci/startup-config.txt')
        .to_return(status: 200, body: config_content)
    end

    it 'downloads startup configuration' do
      result = config_resource.download

      expect(result).to include('Router configuration')
      expect(result).to include('system name-server 8.8.8.8')
      expect(result).to include('interface Bridge0')
    end

    it 'returns plain text content' do
      result = config_resource.download

      expect(result).to be_a(String)
    end
  end
end
