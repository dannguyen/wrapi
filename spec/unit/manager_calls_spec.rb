require 'spec_helper'

describe 'Wrapi::Manager' do 

  before(:each) do 
    @client = double()
    @client.stub(:call_the_api){ 'Hello' }
    @client.stub(:call_the_api_with_args){|a| "Hello #{a}" }
    @manager = Manager.new
    @manager.add_clients(@client)

  end

  describe '#fetch' do 

    context 'when foo is a symbol or string' do 
      it 'should invoke :foo upon a client' do 
        expect(@client).to receive(:call_the_api)
        @manager.fetch(:call_the_api)
      end

      it 'expects the second argument to be an options hash' do 
        expect{@manager.fetch(:call_the_api_with_args, 'argument!')}.to raise_error ArgumentError
      end

    end

    context 'optional options' do 
      describe ':arguments' do 
        it 'expects :arguments as an array' do 
          expect{@manager.fetch(:call_the_api_with_args, arguments: 'world')}.to raise_error ArgumentError
        end

        it 'expects :arguments to be sent to the client' do 
          expect(@client).to receive(:call_the_api_with_args).with('world')
          @manager.fetch(:call_the_api_with_args, arguments: ['world'])
        end

        it 'does not dupe arguments' 
      end

      describe 'while_condition' do 
        it 'expects a lambda' do 
          expect{@manager.fetch(:call_the_api, while_condition: 'not a lambda')}.to raise_error ArgumentError
        end

        context 'within loop' do 

          before(:each) do 
            @lambda = double('Proc')
            @lambda.stub(:class){"Proc"}
            @lambda.stub(:call){|loop_state,args| loop_state.iterations < 2}
          end

          it 'calls lambda with arity of two' do 
            expect(@lambda).to receive(:call).with(an_instance_of(Hashie::Mash), an_instance_of(Array))
            @manager.fetch(:call_the_api, while_condition: @lambda)
          end


          it 'loops until while_condition is met' do 
            expect(@client).to receive(:call_the_api).exactly(2).times
            # while_condition is evaluated thrice
            expect(@lambda).to receive(:call).exactly(3).times
            @manager.fetch(:call_the_api, while_condition: @lambda)
          end

        end


      end

    end
  end

  describe '#fetch_batch' do 
    context 'required options' do 
      describe ':while_condition' do 
        it 'must be present'
        it 'must be a lambda with arity of two'
        it 'must return a boolean'
      end

      describe ':response_callback' do 
        it 'if present, must be a lambda with arity of two'
        it "lambda's second argument is an array"
      end
    end

    context 'optional options' do 
      describe ':yield_to' do 
        context 'exists' do 
          it 'must be a block with arity of one'          
        end
      
        context 'does not exist' do 
          it 'returns an array of responses'
        end
      end
    end
  end

end