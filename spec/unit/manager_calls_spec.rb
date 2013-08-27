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

      describe '#response_callback' do 
          before(:each) do 
            @lambda = double('Proc')
            @lambda.stub(:class){"Proc"}
            @lambda.stub(:call){|loop_state, args| loop_state.iterations < 2}
          end



        it 'if present, must be a lambda with arity of two' do 
          expect{@manager.fetch(:call_the_api, response_callback: "not a proc")}.to raise_error ArgumentError
          # must have arity of two
          expect{@manager.fetch(:call_the_api, response_callback: ->(a,b,c){ a }) }.to raise_error ArgumentError
        end
        

        context 'invocation' do 
          it "called with loop_state and arguments" do 
            @lambda = double('Proc')
            @lambda.stub(:class){"Proc"}
            @lambda.stub(:arity){2}
            @lambda.stub(:call){|loop_state,args|  }

            expect(@lambda).to receive(:call).with(an_instance_of(Hashie::Mash), an_instance_of(Array))
            @manager.fetch(:call_the_api, response_callback: @lambda)
          end

          it "executes after loop_state is modified" do
            @hash = {:increments => 0}
            @lambda = ->(loop_state, args){ args[0][:increments] = loop_state.iterations }
            @manager.fetch(:call_the_api_with_args, arguments: [@hash], response_callback: @lambda)

            expect(@hash[:increments]).to eq 1
          end
        end        
      end

      describe 'yielding a block' do

        context 'exists' do 
          it 'must be a Proc with arity of one FetchedResponse' do 
            expect{ |b|
              @manager.fetch(:call_the_api, &b)   
            }.to yield_with_args FetchedResponse
          end

          it 'must yield as many times as there are iterations' do 
            expect{ |b| 
              @manager.fetch(:call_the_api, {while_condition: ->(x,y){ x.iterations < 2 }},  &b)
            }.to yield_control.exactly(2).times 
          end

          it 'must return an empty array' do 
            expect(@manager.fetch(:call_the_api){  }).to be_empty
          end
        end
      
        context 'does not exist' do 
          it 'returns an array of responses' do 
            expect(@manager.fetch(:call_the_api) ).to be_an Array
          end

          it 'contains FetchedResponse objects' do 
            @resp = @manager.fetch(:call_the_api).first
            expect( @resp ).to be_a FetchedResponse
            expect(@resp.body).to eq 'Hello'
          end
        end        
      end


    end
  end


  describe '#fetch_single' do 
    it 'returns first FetchedResponse body as a convenience' do 
      expect(@manager.fetch_single(:call_the_api)).to eq 'Hello'
    end

    it 'raises an error if block is given' do 
      expect{@manager.fetch_single(:call_the_api){|x| } }.to raise_error ArgumentError
    end
  end

  describe '#fetch_batch' do 
    context 'required options' do 
      describe ':while_condition' do 
        it 'must be present' do 
          expect{ @manager.fetch_batch(:call_the_api, response_callback: ->(a,b){} ) }.to raise_error ArgumentError
        end
      end  
    end
  end

end