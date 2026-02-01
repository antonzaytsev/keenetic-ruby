require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Usb do
  let(:client) { Keenetic::Client.new }
  let(:usb) { client.usb }

  before { stub_keenetic_auth }

  describe '#devices' do
    let(:devices_response) do
      {
        'device' => [
          {
            'port' => 1,
            'manufacturer' => 'SanDisk',
            'product' => 'Cruzer Blade',
            'serial' => '12345678',
            'class' => 0,
            'speed' => 'high',
            'connected' => true
          },
          {
            'port' => 2,
            'manufacturer' => 'Seagate',
            'product' => 'Backup Plus',
            'serial' => '87654321',
            'class' => 0,
            'speed' => 'super',
            'connected' => true
          }
        ]
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/usb')
        .to_return(status: 200, body: devices_response.to_json)
    end

    it 'returns list of USB devices' do
      result = usb.devices

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first[:port]).to eq(1)
      expect(result.first[:manufacturer]).to eq('SanDisk')
      expect(result.first[:product]).to eq('Cruzer Blade')
    end

    it 'normalizes device data' do
      result = usb.devices

      expect(result.first[:serial]).to eq('12345678')
      expect(result.first[:speed]).to eq('high')
    end

    it 'normalizes boolean values' do
      result = usb.devices

      expect(result.first[:connected]).to eq(true)
    end

    context 'when no devices connected' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/usb')
          .to_return(status: 200, body: '{"device": []}')
      end

      it 'returns empty array' do
        expect(usb.devices).to eq([])
      end
    end

    context 'when response is array directly' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/usb')
          .to_return(status: 200, body: '[{"port": 1, "connected": true}]')
      end

      it 'handles array response' do
        result = usb.devices

        expect(result).to be_an(Array)
        expect(result.first[:port]).to eq(1)
      end
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/usb')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty array' do
        expect(usb.devices).to eq([])
      end
    end

    context 'when response is not valid' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/usb')
          .to_return(status: 200, body: '"invalid"')
      end

      it 'returns empty array' do
        expect(usb.devices).to eq([])
      end
    end
  end

  describe '#media' do
    let(:media_response) do
      {
        'media' => [
          {
            'name' => 'sda1',
            'label' => 'USB_DRIVE',
            'uuid' => '1234-5678',
            'fs' => 'ext4',
            'mountpoint' => '/media/USB_DRIVE',
            'total' => 32000000000,
            'used' => 16000000000,
            'free' => 16000000000
          },
          {
            'name' => 'sdb1',
            'label' => 'BACKUP',
            'uuid' => 'abcd-efgh',
            'fs' => 'ntfs',
            'mountpoint' => '/media/BACKUP',
            'total' => 1000000000000,
            'used' => 500000000000,
            'free' => 500000000000
          }
        ]
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/media')
        .to_return(status: 200, body: media_response.to_json)
    end

    it 'returns list of storage partitions' do
      result = usb.media

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first[:name]).to eq('sda1')
      expect(result.first[:label]).to eq('USB_DRIVE')
    end

    it 'includes storage details' do
      result = usb.media

      expect(result.first[:fs]).to eq('ext4')
      expect(result.first[:mountpoint]).to eq('/media/USB_DRIVE')
      expect(result.first[:total]).to eq(32000000000)
      expect(result.first[:used]).to eq(16000000000)
      expect(result.first[:free]).to eq(16000000000)
    end

    context 'when no media mounted' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/media')
          .to_return(status: 200, body: '{"media": []}')
      end

      it 'returns empty array' do
        expect(usb.media).to eq([])
      end
    end

    context 'when response is array directly' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/media')
          .to_return(status: 200, body: '[{"name": "sda1", "fs": "ext4"}]')
      end

      it 'handles array response' do
        result = usb.media

        expect(result).to be_an(Array)
        expect(result.first[:name]).to eq('sda1')
      end
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/media')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty array' do
        expect(usb.media).to eq([])
      end
    end
  end

  describe '#storage' do
    it 'is an alias for media' do
      stub_request(:get, 'http://192.168.1.1/rci/show/media')
        .to_return(status: 200, body: '{"media": []}')

      expect(usb.storage).to eq(usb.media)
    end
  end

  describe '#eject' do
    it 'sends eject command for specified port' do
      eject_stub = stub_request(:post, 'http://192.168.1.1/rci/usb/eject')
        .with(body: { 'port' => 1 }.to_json)
        .to_return(status: 200, body: '{}')

      usb.eject(port: 1)

      expect(eject_stub).to have_been_requested
    end

    it 'works with different port numbers' do
      eject_stub = stub_request(:post, 'http://192.168.1.1/rci/usb/eject')
        .with(body: { 'port' => 2 }.to_json)
        .to_return(status: 200, body: '{}')

      usb.eject(port: 2)

      expect(eject_stub).to have_been_requested
    end
  end
end
