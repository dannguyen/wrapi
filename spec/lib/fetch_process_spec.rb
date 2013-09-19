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
          while_condition: ->(f_process, args){ f_process.iterations < 1},
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
            expect(@process.iterations).to eq 0
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
        it 'should increment @iterations' do 
          expect(@process.iterations).to eq 1
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
          expect(@process.iterations).to eq 2
        end
      end
    end


    describe 'error fixing'  do 
      before(:each) do 
        @client = ManagedClient.new("1.1")
        @process = FetchProcess.new( @client, :ceil)
        @resp = nil
        @process.execute{|r| @resp = r}
      end

      context 'how an error has impact, pre-fix' do 
        it 'should be an error' do 
          expect(@process.latest_response_successful?).to be_false
        end

        it 'has an unfixed_error?' do 
          expect(@process.unfixed_error?).to be_true
        end

        it 'should not be #ready_to_execute?' do 
          expect(@process.ready_to_execute?).to be_false
        end

        it 'should have no iterations' do 
          expect(@process.iterations).to eq 0
        end
      end

      describe '#fix_error' do 

        describe 'requires true/false for result of passed in block' do 
          it 'should raise error if non-Boolean' do 
            b = Proc.new{|r| "not truthy" }
            expect{ @process.fix_error(&b) }.to raise_error ImproperErrorHandling
          end
        end


        describe 'upon a false fix' do 
          it 'must still have an #unfixed_error?' do 
            @process.fix_error{ |r|  false }
            expect(@process.unfixed_error?).to be_true
          end
        end


        describe 'when handler returns true' do 
          it 'no longer has an error by default' do 
            @process.fix_error do |p|
              "i didn't actually do anything"
              true
            end

            expect(@process).to be_ready_to_execute
          end
        end


        describe 'an actual fix' do 
          it 'execute successfully works' do 
            @process.fix_error do |p|
              # replace the client
              p.set_client(ManagedClient.new(1.1)) 
              true           
            end

            @process.execute do |resp|
              expect(resp).to be_success
              expect(resp.body).to eq 2
            end
          end
        end


      end


    end
  end
end