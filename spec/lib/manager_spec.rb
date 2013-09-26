require 'spec_helper'

describe "Wrapi::Manager" do

  before(:each) do 
    @manager = Manager.new    
  end

  context 'queue interface' do 
    it 'should have a queue with initially 0 clients' do 
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

    it 'should remove clients' do 
      @manager.add_clients(['a', 'b'])
      expect(@manager.remove_client 'a').to be_true
      expect(@manager.remove_client 'b').to be_true
      expect(@manager.remove_client 'b').to be_false

      expect(@manager.has_clients?).to be_false
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

  context 'client refreshing -- delegated to the process' do 

    # Not sure where this should be handled, in fetch process or not...
    describe '#active_client' do 
      it 'should be the first client that gets sent to a process'
    end

    describe '#find_next_client' do 
      it 'should be nil if no other client' do 
        expect(@manager.find_next_client).to be_nil  
      end

      it 'should optionally accept a client that the manager does not want to match' do 
        @client_a = 'Hey'
        @manager.add_clients(@client_a)        
        expect(@manager.find_next_client(@client_a)).to be_nil
        # sanity check:
        expect(@manager.find_next_client).to eq @client_a
      end

      describe 'optional filter block' do 
        before(:each) do 
          @client_a = 'Hey'
          @client_b = 'You'
          @manager.add_clients([@client_a, @client_b])
        end

        it 'should accept optional block to do filtering for client' do 
          expect(@manager.find_next_client{|c| c.upcase == 'YOU'}).to eq @client_b
        end

        it 'should not re-select the same client instance' do 
          expect(@manager.find_next_client(@client_b){|c| c.upcase == 'YOU'}).to be_nil
        end
      end
    end
  end

  context 'error handling'  do 
    context 'basic error registering' do 
      it 'should allow us to register errors by type' do
        @handler = ->(x){  true  }
        @manager.register_error_handler(StandardError, @handler)

        expect(@manager.get_error_handler(StandardError)).to eq @handler
      end

      # this test is a bit iffy
      it 'should allow us to register errors with a block' do 
        @manager.register_error_handler(NoMethodError) do |x|
          true
        end
      end

      # 
      it 'should allow us to register errors with a block' do 
        expect{ @manager.register_error_handler(NoMethodError)  }.to raise_error ArgumentError
      end

    end
  end


end
