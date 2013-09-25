require 'spec_helper'

describe 'Wrapi::FetchProcess error_handling' do

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

      context 'error tracking' do 
        describe '#error_count' do 
          it 'should return integer of errors encountered' do 
            expect(@process.error_count).to eq 1
          end
        end

        describe '#error_count by type' do 
          it 'should return error by kind and respect inheritance' do 
            expect(@process.error_count(StandardError)).to eq 1
            expect(@process.error_count(NoMethodError)).to eq 1

            expect(@process.error_count(ArgumentError)).to eq 0
          end
        end
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