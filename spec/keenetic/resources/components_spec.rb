require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Components do
  let(:client) { Keenetic::Client.new }
  let(:components) { client.components }

  before { stub_keenetic_auth }

  describe '#installed' do
    let(:installed_response) do
      {
        'component' => [
          { 'name' => 'transmission', 'version' => '3.0', 'size' => 2048000 },
          { 'name' => 'opkg', 'version' => '1.0', 'size' => 512000 }
        ]
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/components')
        .to_return(status: 200, body: installed_response.to_json)
    end

    it 'returns list of installed components' do
      result = components.installed

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first[:name]).to eq('transmission')
    end

    it 'includes component details' do
      result = components.installed

      expect(result.first[:version]).to eq('3.0')
      expect(result.first[:size]).to eq(2048000)
    end

    context 'when no components installed' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/components')
          .to_return(status: 200, body: '{"component": []}')
      end

      it 'returns empty array' do
        expect(components.installed).to eq([])
      end
    end

    context 'when response is array directly' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/components')
          .to_return(status: 200, body: '[{"name": "test"}]')
      end

      it 'handles array response' do
        result = components.installed

        expect(result).to be_an(Array)
        expect(result.first[:name]).to eq('test')
      end
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/components')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty array' do
        expect(components.installed).to eq([])
      end
    end
  end

  describe '#available' do
    let(:available_response) do
      {
        'component' => [
          { 'name' => 'transmission', 'version' => '3.0', 'description' => 'BitTorrent client' },
          { 'name' => 'minidlna', 'version' => '1.2', 'description' => 'DLNA server' }
        ]
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/components/available')
        .to_return(status: 200, body: available_response.to_json)
    end

    it 'returns list of available components' do
      result = components.available

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first[:name]).to eq('transmission')
    end

    it 'includes component descriptions' do
      result = components.available

      expect(result.first[:description]).to eq('BitTorrent client')
    end

    context 'when no components available' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/components/available')
          .to_return(status: 200, body: '{"component": []}')
      end

      it 'returns empty array' do
        expect(components.available).to eq([])
      end
    end
  end

  describe '#install' do
    it 'installs a component by name' do
      install_stub = stub_request(:post, 'http://192.168.1.1/rci/components/install')
        .with(body: { 'name' => 'transmission' }.to_json)
        .to_return(status: 200, body: '{}')

      components.install(name: 'transmission')

      expect(install_stub).to have_been_requested
    end
  end

  describe '#remove' do
    it 'removes a component by name' do
      remove_stub = stub_request(:post, 'http://192.168.1.1/rci/components/remove')
        .with(body: { 'name' => 'transmission' }.to_json)
        .to_return(status: 200, body: '{}')

      components.remove(name: 'transmission')

      expect(remove_stub).to have_been_requested
    end
  end
end
