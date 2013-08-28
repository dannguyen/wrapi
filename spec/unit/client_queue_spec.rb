require 'spec_helper'

describe 'ClientQueue' do 

  describe 'initialization' do 


    it 'accepts an array' do 
      expect(ClientQueue.new([]).size).to eq 0      
    end

    before(:each) do 
      @queue = ClientQueue.new()
    end

    context "emptiness" do 
      it 'should be #empty?' do
        expect(@queue.empty?).to be_true
      end

      it 'should not have any clients' do 
        expect(@queue.find_client).to be_nil
      end
    end

    context "add clients" do 
      before(:each) do 
        @client = ManagedClient.new(nil)
      end

      it 'should raise argument if not a managed client' do 
        expect{ @queue.add_clients([1,2]) }.to raise_error ArgumentError
      end

      it 'should add one client' do 
        @queue.add_client(@client)
        expect(@queue.size).to eq 1
      end

      it 'should add an array of clients' do 
        @queue.add_clients(4.times.map{ @client } )
        expect(@queue.size).to eq 4
      end
    end



  end
end