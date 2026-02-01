require_relative '../../spec_helper'

RSpec.describe Keenetic::Resources::Users do
  let(:client) { Keenetic::Client.new }
  let(:users) { client.users }

  before { stub_keenetic_auth }

  describe '#all' do
    let(:users_response) do
      {
        'user' => [
          {
            'name' => 'admin',
            'tag' => ['http', 'cli', 'cifs', 'ftp', 'vpn']
          },
          {
            'name' => 'guest',
            'tag' => ['http', 'cifs']
          }
        ]
      }
    end

    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/user')
        .to_return(status: 200, body: users_response.to_json)
    end

    it 'returns list of users' do
      result = users.all

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first[:name]).to eq('admin')
    end

    it 'includes user permissions' do
      result = users.all

      expect(result.first[:tag]).to include('http', 'cli')
    end

    context 'when no users exist' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/user')
          .to_return(status: 200, body: '{"user": []}')
      end

      it 'returns empty array' do
        expect(users.all).to eq([])
      end
    end

    context 'when response is array directly' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/user')
          .to_return(status: 200, body: '[{"name": "test"}]')
      end

      it 'handles array response' do
        result = users.all

        expect(result).to be_an(Array)
        expect(result.first[:name]).to eq('test')
      end
    end

    context 'when response is empty' do
      before do
        stub_request(:get, 'http://192.168.1.1/rci/show/user')
          .to_return(status: 200, body: '{}')
      end

      it 'returns empty array' do
        expect(users.all).to eq([])
      end
    end
  end

  describe '#find' do
    before do
      stub_request(:get, 'http://192.168.1.1/rci/show/user')
        .to_return(status: 200, body: '{"user": [{"name": "admin"}, {"name": "guest"}]}')
    end

    it 'finds user by name' do
      result = users.find('admin')

      expect(result[:name]).to eq('admin')
    end

    it 'returns nil when not found' do
      result = users.find('nonexistent')

      expect(result).to be_nil
    end
  end

  describe '#create' do
    it 'creates a new user with tags' do
      create_stub = stub_request(:post, 'http://192.168.1.1/rci/user')
        .with { |req|
          body = JSON.parse(req.body)
          body['name'] == 'guest' &&
            body['password'] == 'guestpass' &&
            body['tag'] == ['http', 'cifs']
        }
        .to_return(status: 200, body: '{}')

      users.create(name: 'guest', password: 'guestpass', tag: ['http', 'cifs'])

      expect(create_stub).to have_been_requested
    end

    it 'creates a user without tags' do
      create_stub = stub_request(:post, 'http://192.168.1.1/rci/user')
        .with { |req|
          body = JSON.parse(req.body)
          body['name'] == 'guest' && !body.key?('tag')
        }
        .to_return(status: 200, body: '{}')

      users.create(name: 'guest', password: 'pass')

      expect(create_stub).to have_been_requested
    end
  end

  describe '#delete' do
    it 'deletes user by name' do
      delete_stub = stub_request(:post, 'http://192.168.1.1/rci/user')
        .with(body: { 'name' => 'guest', 'no' => true }.to_json)
        .to_return(status: 200, body: '{}')

      users.delete(name: 'guest')

      expect(delete_stub).to have_been_requested
    end
  end
end
