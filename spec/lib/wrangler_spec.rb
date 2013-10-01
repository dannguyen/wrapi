require 'spec_helper'

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
  end


  context '@logger is an attr_accessor' do
    it 'should be nil by default' do 
      expect(AwesomeApeWrangler.new.logger).to be_nil
    end

    it 'should be allowed to be set' do 
      wrangler = AwesomeApeWrangler.new 
      wrangler.logger = STDOUT

      expect(wrangler.logger).to eq STDOUT
    end

  end

  context 'error handling' do 
     it 'runs #register_error_handlers' do 
        ape = AwesomeApeWrangler.new
        expect(ape.get_error_handler(ApeError)).to be_a Proc
     end
  end
end




class ApeError < StandardError; end

class AwesomeApeWrangler 
  include Wrapi::Wrangler

  def register_error_handlers
    register_error_handler(ApeError, ->(f_process, fetcher_instance ){ return false })
  end
end

