require 'spec_helper'

describe "Wrapi::Manager" do

  before(:each) do 
    @manager = Manager.new    
  end

  context 'pool interface' do 
    it 'should have a pool with initially 0 clients' do 
      expect(@manager.client_count).to eq 0
    end

    it 'should allow the addition of a single client' do 
      @manager.add_clients({name: 'hey', id: 'you', desc: 'guys'})
      expect(@manager.client_count).to eq 1
    end

    it 'should allow the addition of several clients' do 
      @manager.add_clients([1,2,3])
      expect(@manager.client_count).to eq 3
    end
  end

  context 'wrap in managed clients' do 
    before(:each) do 
      @client = double()
      @client.stub(:inspect){ 'inspected' }

      @manager.add_clients(@client)
    end

    it 'should wrap each client in ManagedClient' do 
      expect(@manager.find_client).to be_a ManagedClient
    end
  end


end
