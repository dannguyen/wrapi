require 'spec_helper'

describe 'Wrapi::Wrangler' do 

  it 'should be a class or module?'

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

  context 'credentializing' do 
    it 'should read a list of credentials'
  end


  context 'convenience calls' do 
    it 'should use manager to handle batch calls'
    it 'should use manager to handle singular calls'
  end

end