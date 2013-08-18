require 'spec_helper'

class AwesomeApeWrangler 
  include Wrapi::Wrangler
end

describe 'Wrapi::Wrangler' do 


  context 'configuration' do 
    context 'client_wrapping' do 
      it 'should wrap a client in Wrapi::Client'
      it 'should configure client instantiation'
      it 'should configure client rate limited error'
      it 'should configure other errors'
      it 'should configure how rate readiness is set'

      context 'rate readiness' do 
        it 'should have a configuration hash'
        it 'should have a default wait'
      end
    end


    context 'error handling' do 
      before(:each) do 
        @klass = AwesomeApeWrangler.dup
      end

      it 'should have @@handled_errors' do 
        expect(@klass.handled_errors).to be_a Hashie::Mash
      end

      describe '::handle_error' do 

        context 'first argument' do 
          it 'should raise ArgumentError when not Exception class' do 
            expect{@klass.handle_error(String)}.to raise_error ArgumentError
          end
         end

        context 'block handling' do 
          it 'raises LocalJumpError without block' do 
            expect{@klass.handle_error(StandardError){ 'no arg' } }.to raise_error LocalJumpError         
          end
        end

        context 'modifies ::handled_errors' do 
          it 'should add to list of handled errors' do 
            expect(@klass.handled_errors ).to be_empty
            @klass.handle_error(ArgumentError){|k| puts k}
            expect(@klass.handled_errors[ArgumentError] ).to be_a Hashie::Mash
          end
    
        end
      end


      describe '::handle_rate_limited_error' do 
        it 'should accept timeout parameter'

      end


    end

  end

  context 'credentializing' do 
    it 'shoudl set credentializing block so client can configure on unique basis'
    it 'should read a list of credentials'
  end


  context 'convenience calls' do 
    it 'should use manager to handle batch calls'
    it 'should use manager to handle singular calls'
  end

end