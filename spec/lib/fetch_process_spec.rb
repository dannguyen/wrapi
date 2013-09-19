require 'spec_helper'

describe 'Wrapi::FetchProcess', focus: true do

  

  context 'initialization' do 
    describe 'arguments' do 
  
      let(:a_client){ ManagedClient.new({}) }

      it 'sets first argument to :client' do 
        @process = FetchProcess.new(a_client, :foo)
        expect(@process.client).to be a_client
      end

      it 'expects 1st argument to be a ManagedClient' do 
        expect{ FetchProcess.new('not a managed_client', :foo)}.to raise_error ArgumentError
      end

      it 'has 2nd argument be the @process_name' do 
        @process = FetchProcess.new(a_client, :foo)
        expect(@process.process_name).to eq :foo
      end

      context 'options hash' do 
        it 'accepts :arguments as an Array' do 
          expect{ FetchProcess.new(a_client, :foo, arguments: {} ) }.to raise_error ArgumentError
        end

        it 'accepts :while_condition if it responds to :call' do 
          expect{ FetchProcess.new(a_client, :foo, while_condition: true ) }.to raise_error ArgumentError
        end

        it 'accepts :response_callback if it has arity of 2' do 
          expect{ FetchProcess.new(a_client, :foo, response_callback: ->(a,b,c){ 'boo' } ) }.to raise_error ArgumentError
        end
      end
    end
  end



  context 'public methods' do 
    before(:each) do 
      @client = ManagedClient.new({})
      @foo = :foo
      @my_arg = []
      @process = FetchProcess.new(
        @client,
        @foo,
        {
          arguments: [@my_arg],
          while_condition: ->(f_process, args){ f_process.iterations < 1},
          response_callback: ->(f_process, args){ args[0] << '!'}
        }
      )
    end


    describe '#client' do 
      it 'should return client instance' do 
        expect(@process.client).to be @client 
      end
    end

    describe '#set_client' do 
      it 'should change client' do 
        new_client = ManagedClient.new('newfoo')
        @process.set_client(new_client)
        expect(@process.client).to be new_client
      end

      it 'should raise error on non ManagedClient' do 
        expect{@process.set_client('bad foo')}.to raise_error ArgumentError
      end
    end



    describe '#proceed!' do
      before(:each) do 
        @process.proceed!
      end

      context 'post-#proceed! effects' do 
        it 'should increment @iterations' do 
          expect(@process.iterations).to eq 1
        end

        it 'should perform @response_callback' do 
          expect(@process.arguments.first).to eq ['!']
        end

        it 'does not modify original arguments' do 
          expect(@my_arg).to eq []
        end
      end


      describe '#while_condition?' do 
        it 'should change to false upon first call of (this) #proceed!' do 
          expect(@process.while_condition?).to be_false
        end

        it 'should not #proceed! when while_condition? is false' do 
          expect{@process.proceed!}.to raise_error ProcessingWhileFalseError
        end

        it 'should allow _proceed! no matter what' do 
          # this is probably a bad idea...
          @process._proceed!
          expect(@process.iterations).to eq 2
        end

      end

      describe 'latest_body' do 
        it 'should return .body of latest response' do 

        end
      end


      describe 'latest_response?' do 
        it 'is true if .body exists'
        it 'is false if no .body exists'
      end

    end
    
  end

end