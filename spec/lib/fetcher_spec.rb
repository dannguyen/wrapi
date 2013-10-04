require 'spec_helper'

describe "Wrapi::Fetcher" do

  before(:each) do 
    @fetcher = Fetcher.new    
  end

  context 'queue interface' do 
    it 'should have a queue with initially 0 clients' do 
      expect(@fetcher.client_count).to eq 0
    end

    it 'should allow the addition of a single client' do 
      @fetcher.add_clients({name: 'hey', id: 'you', desc: 'guys'})
      expect(@fetcher.client_count).to eq 1
    end

    it 'should allow the addition of several clients' do 
      @fetcher.add_clients([1,2,3])
      expect(@fetcher.client_count).to eq 3
    end

    it 'should remove clients' do 
      @fetcher.add_clients(['a', 'b'])
      expect(@fetcher.remove_client 'a').to be_true
      expect(@fetcher.remove_client 'b').to be_true
      expect(@fetcher.remove_client 'b').to be_false

      expect(@fetcher.has_clients?).to be_false
    end
  end


  describe '#has_process? and #current_process_client' do 
    before(:each) do 
      @client = double('a client')
      @client.stub(:foo){ 'UP!'}

      @fetcher.add_clients(@client)
    end
    
    context 'initial state' do  

      it 'doesnt #has_process? yet' do 
        expect(@fetcher.has_process?).to be_false
      end

      it '#current_process_client is nil until process starts' do 
        expect(@fetcher.current_process_client).to be_nil
      end
    end

    context 'after process runs' do 
      before(:each) do 
         @fetcher.fetch(:foo)
      end

      it 'now #has_process?' do 
        expect(@fetcher.has_process?).to be_true
      end

      it 'now has a #current_process_client' do 
        expect(@fetcher.current_process_client).to eq @fetcher.current_process.client
      end

      context 'delegates methods to #current_process' do 
        it 'should have #iteration_count' do 
          expect(@fetcher.current_process_iteration_count).to eq 1
        end

        it 'should have #latest_response' do 
          expect(@fetcher.current_process_latest_response).to eq @fetcher.current_process.latest_response
        end
      end



    end
  end

  context 'wrap in managed clients' do 
    before(:each) do 
      @client = double()
      @client.stub(:inspect){ 'inspected' }

      @fetcher.add_clients(@client)
    end

    it 'should wrap each client in ManagedClient' do 
      expect(@fetcher.find_client).to be_a ManagedClient
    end
  end

  context 'client refreshing -- delegated to the process' do 

    # Not sure where this should be handled, in fetch process or not...
    describe '#active_client' do 
      it 'should be the first client that gets sent to a process'
    end

    describe '#find_next_client' do 
      it 'should be nil if no other client' do 
        expect(@fetcher.find_next_client).to be_nil  
      end

      it 'should optionally accept a client that the fetcher does not want to match' do 
        @client_a = 'Hey'
        @fetcher.add_clients(@client_a)        
        expect(@fetcher.find_next_client(@client_a)).to be_nil
        # sanity check:
        expect(@fetcher.find_next_client).to eq @client_a
      end

      describe 'optional filter block' do 
        before(:each) do 
          @client_a = 'Hey'
          @client_b = 'You'
          @fetcher.add_clients([@client_a, @client_b])
        end

        it 'should accept optional block to do filtering for client' do 
          expect(@fetcher.find_next_client{|c| c.upcase == 'YOU'}).to eq @client_b
        end

        it 'should not re-select the same client instance' do 
          expect(@fetcher.find_next_client(@client_b){|c| c.upcase == 'YOU'}).to be_nil
        end
      end
    end
  end

  context 'error handling'  do 
    context 'basic error registering' do 
      it 'should allow us to register errors by type' do
        @handler = ->(x){  true  }
        @fetcher.register_error_handler(StandardError, @handler)

        expect(@fetcher.get_error_handler(StandardError)).to eq @handler
      end

      # this test is a bit iffy
      it 'should allow us to register errors with a block' do 
        @fetcher.register_error_handler(NoMethodError) do |x|
          true
        end
      end

      # 
      it 'should allow us to register errors with a block' do 
        expect{ @fetcher.register_error_handler(NoMethodError)  }.to raise_error ArgumentError
      end

    end
  end


end
