require 'spec_helper'

class AwesomeApeWrangler 
  include Wrapi::Wrangler

  def register_error_handling
    register_error_handler(LocalJumpError, ->(f_process, manager_instance ){ return false })
  end
end

describe 'Wrapi::Wrangler' do 


  context 'credentializing'  do 

    it 'has a credentials_array that can be accessed' do 
      pending " figuring out parsing order"
      expect(AwesomeApeWrangler.new.credentials_array).to be_an Array
    end

    describe '#parse_credentials' do 
      it 'should set credentializing block so client can configure on unique basis' do 
        pending " figuring out parsing order"
      # expect{|b|  AwesomeApeWrangler.parse_credentials }.to yield_with_args( AwesomeApeWrangler.credentials_array) 
      end
    end

    it 'should read from credentials_array '
  end


  context 'error handling' do 
     it 'runs #register_error_handling' do 
        ape = AwesomeApeWrangler.new
        expect(ape.get_error_handler(LocalJumpError)).to be_a Proc
     end
  end
  
end



=begin


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
  end

=end