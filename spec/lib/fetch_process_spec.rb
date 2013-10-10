require 'spec_helper'

describe 'Wrapi::FetchProcess' do

  

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
      @client = ManagedClient.new('hey')
      @foo = :sub
      @my_arg = ['hey', 'Hello']
      @process = FetchProcess.new(
        @client,
        @foo,
        {
          arguments: @my_arg,
          while_condition: ->(f_process, args){ f_process.iteration_count < 1},
          response_callback: ->(f_process, args){ args[1] << '!'}
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


    describe '#execute' do 
      context 'inside block' do 
        it 'should yield a FetchResponse' do 
          expect{|b| @process.execute(&b )}.to yield_with_args(FetchedResponse)
        end
      end


      context 'post execute' do 
        before(:each) do 
          @response_array = []
          @process.execute do |resp|
            @response_array << resp
          end
        end
      
        context 'sanity check' do 
          it 'should be a successful execution' do 
            expect(@response_array.first.status).to eq :success 
          end
        end


        context 'does NOT run #proceed!' do 
          it 'requires that proceed! is executed manually' do 
            expect(@process.iteration_count).to eq 0
          end
        end

        context 'on while_condition' do 
          it 'should not #execute again when while_condition? is false' do 
            @process.proceed! ## for now, we  proceed! manually
            expect{@process.execute{|r| 'foo'}}.to raise_error ExecutingWhileFalseError
          end
        end


        describe 'latest_body' do 
          it 'should return .body of latest_response' do 
            expect(@process.latest_body).to eq 'Hello'
          end
        end


        describe '#latesst_response methods' do 
          before(:each) do 
            @ap =  FetchProcess.new ManagedClient.new('a'), :upcase
            @bp  =  FetchProcess.new ManagedClient.new('b'), :not_a_foo
          end 

          describe 'latest_response?' do 
            it 'is true if executed at least once' do 
              @ap.execute{ }
              expect(@ap.latest_response?).to be_true
            end

            it 'is false pre execution' do 
              expect(@ap.latest_response?).to be_false
            end
          end

          describe '#latest_response_successful?' do
            it 'is true if latest_response :success? is true' do 
              @ap.execute{ }
              expect(@ap.latest_response_successful?).to be_true
            end

            it 'is false if latest_response :success? is false' do 
              @bp.execute{ }
              expect(@bp.latest_response_successful?).to be_false
            end
          end

        end
      end


    end

    describe '#proceed!' do
      before(:each) do 
        @process.proceed!
      end

      context 'post-#proceed! effects' do 
        it 'should increment @iteration_count' do 
          expect(@process.iteration_count).to eq 1
        end

        it 'should perform @response_callback' do 
          expect(@process.arguments[1]).to eq 'Hello!'
        end

        it 'warning, modifies original arguments' do 
          expect(@my_arg).to eq ['hey', 'Hello!']
        end
      end


      describe '#while_condition? for this particular case' do 
        it 'should change to false upon first call of (this) #proceed!' do 
          expect(@process.while_condition?).to be_false
        end

        it 'should allow #proceed! no matter what' do 
          # this is probably a bad idea...
          @process.proceed!
          expect(@process.iteration_count).to eq 2
        end
      end
    end


    describe '#set_operation' do 
      before(:each) do 
        @mock_client = double()
        @mock_client.stub(:foo){ 'Hello' }
        
        @fetcher = Fetcher.new
        @fetcher.add_clients(@mock_client)
      end

      it 'sanity test since we are throwing in Fetcher' do 
        # We're using Fetcher here since FetchProcess requires
        # annoying conversion to ManagedClient
        expect(@mock_client).to receive(:foo)
        @fetcher.fetch_single(:foo)
      end

      it 'throws an error if the argument does not respond_to?:call' do 

        params =  {
                  response_callback: ->(loop_state, resp){ loop_state.set_operation('Not a foo!') }
                }
      
        expect{@fetcher.fetch(:foo, params) }.to raise_error ArgumentError
      end


      it 'changes the operation that the process executes' do   
        @newfoo = double()
        @newfoo.stub(:call){ 'hey'}

        @params = {
          while_condition: ->(loop_state, resp){ loop_state.iteration_count < 3},
          response_callback: ->(loop_state, resp){ loop_state.set_operation(@newfoo) }
        }

     
        expect(@mock_client).to receive(:foo).exactly(1).times
        expect(@new_foo).to receive(:call).exactly(2).times
        # we call #set_operation after the first response, i.e. during :response_callback
        
        @fetcher.fetch_batch(:foo, @params ){|resp| }
      end



      it 'correctly encloses the non-thread safe value' do
      # or whatever. This test is of limited use and should be removed
        arbval = 100
        dofoo = double()
        dofoo.stub(:call){ arbval += 10}

        params = {
          while_condition: ->(loop_state, resp){ loop_state.iteration_count < 3},
          response_callback: ->(loop_state, resp){ loop_state.set_operation(dofoo) }
        }

        @fetcher.fetch_batch(:foo, params ){|resp| }
        expect(arbval).to eq 120
      end

      describe '#set_generic_operation' do 
        before(:each) do 
          client = "client"
        
          @fetcher = Fetcher.new
          @fetcher.add_clients(@client)

        end

        it 'works the same as set_operation, except invokes :set_generic_operation on client' do 

          params = {
            while_condition: ->(loop_state, resp){ loop_state.iteration_count < 3},
            response_callback: ->(loop_state, resp){ loop_state.set_generic_operation( ->(){ 42} ) }
          }          
          @fetcher.fetch_batch(:upcase, params ){|resp| }
          client = @fetcher.current_process_client

          expect(@fetcher.current_process_client.call_count).to eq 3
        end

        it 'without generic_op, we only have one successful call to client' do 
          non_attached_foo = double()
          non_attached_foo.stub(:call){ }

          params = {
            while_condition: ->(loop_state, resp){ loop_state.iteration_count < 3},
            response_callback: ->(loop_state, resp){ loop_state.set_operation( non_attached_foo ) }
          }          

          # redundant, but the new foo should receive :call twice out of 3 calls
          expect{ non_attached_foo.to receive(:call).exactly(2).times }

          @fetcher.fetch_batch(:upcase, params ){|resp| }

          # client is only aware of 1 call, the very first one
          expect(@fetcher.current_process_client.call_count).to eq 1
        end
      end

  end




    describe '#serialize' do 
      let(:a_client){ ManagedClient.new({}) }

      before(:each) do 
         @process = FetchProcess.new(a_client, :foo, arguments: [1,2,3])
         @serial = @process.serialize
      end

      it 'should be a Hash' do 
        expect(@serial).to be_a Hash
      end

      it 'should also be a Mash' do 
        expect(@serial).to be_a Hashie::Mash
      end

      context 'key/values' do 
        it 'should list arguments' do 
          expect(@serial.arguments).to eq [1,2,3]
        end

        it 'should have @process_name' do 
          expect(@serial.process_name).to eq :foo
        end

        it 'should have @iteration_count' do 
          expect(@serial.iteration_count).to eq 0
        end

        it 'should match process @iteration_count when iterated' do
          @process.proceed! 
          expect(@process.serialize.iteration_count).to eq 1
        end


      end
    end

  end
end