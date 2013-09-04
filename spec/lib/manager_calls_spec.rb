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

        context 'within loop', focus: true do 
          let(:lambda){ Proc.new do |fetch_process,args| 
                args[0].probe(fetch_process,args)
                fetch_process.iterations < 2 
              end
           }

          before(:each) do 
            @foo_probe = double()
            @foo_probe.stub(:probe){|a,b| }
          end

          it 'calls lambda with arity of two' do 
            expect(@foo_probe).to receive(:probe).with(an_instance_of(FetchProcess), an_instance_of(Array))
            @manager.fetch(:call_the_api_with_args, arguments: [@foo_probe], while_condition: lambda)
          end

          it 'loops until while_condition is met' do 
            expect(@client).to receive(:call_the_api_with_args).exactly(2).times
            # while_condition is evaluated thrice

            expect(@foo_probe).to receive(:probe).exactly(3).times
            @manager.fetch(:call_the_api_with_args, arguments: [@foo_probe], while_condition: lambda)
          end
        end
      end




      describe '#response_callback' do 
        let(:lambda){ Proc.new do |fetch_process,args| 
              args[0].probe(fetch_process,args)
              fetch_process.iterations < 2 
            end
         }

        before(:each) do 
          @foo_probe = double()
          @foo_probe.stub(:probe){|a,b| }
        end

        it 'if present, must be a lambda with arity of two' do 
          expect{@manager.fetch(:call_the_api, response_callback: "not a proc")}.to raise_error ArgumentError
          # must have arity of two
          expect{@manager.fetch(:call_the_api, response_callback: ->(a,b,c){ a }) }.to raise_error ArgumentError
        end
        

        context 'invocation' do 
          it "called with fetch_process and arguments" do 
            expect(@foo_probe).to receive(:probe).with(an_instance_of(FetchProcess), an_instance_of(Array))
            @manager.fetch(:call_the_api_with_args, response_callback: lambda, arguments: [@foo_probe])
          end

          it "executes after fetch_process is modified" do
            pending('forget it, I cant get this to work without exposing interface')

            @probe_att = {increments: 0}
            @probe = double()
            @probe.stub(:set_it){|a| a}            

            @callback = ->(fetch_process, args){  
              args[0] = fetch_process.iterations  
              puts "\n\n HEY\n fetch_process: #{fetch_process.iterations}" 
              puts "args: #{args[0][:increments]}"
              puts "hash: #{binded_hash[:increments]}\n\n\n"

            }
            @manager.fetch(:call_the_api_with_args, arguments: [@hash], response_callback: @callback)

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
              @manager.fetch(:call_the_api, {while_condition: ->(x,y){ x.iterations < 2 }}, &b)
            }.to yield_control.exactly(2).times 
          end

          it 'must return an empty array' do 
            results = @manager.fetch(:call_the_api){ |b| }
            expect(results).to be_empty
            expect(results).to be_an(Array) 
          end
        end
      
        context 'does not exist' do 
          it 'returns an array of responses' do 
            results = @manager.fetch(:call_the_api)
            expect(results ).to be_an Array
            expect(results).not_to be_empty
          end

          it 'contains FetchedResponse objects' do 
            @resp = @manager.fetch(:call_the_api).first
            expect( @resp ).to be_a FetchedResponse
            expect(@resp.body).to eq 'Hello'
          end
        end        
      end # 'yielding a block'

      describe 'passing in a IO object via :transcript' do 

        it 'should raise ArgumentError if transcript is non-nil and does not respond to #puts' do 
          expect{ @manager.fetch(:call_the_api, transcript: [404] )}.to raise_error ArgumentError
        end

        it 'should print message to an IO object' do 
          @io = StringIO.new
          @manager.fetch(:call_the_api, transcript: @io)
          expect(@io.string).to match(/:call_the_api with :arguments/)
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