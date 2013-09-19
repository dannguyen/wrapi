require 'spec_helper'

describe 'Wrapi::FetchProcess', focus: true do


  context 'initialization' do 
    describe 'arguments' do 
      it 'sets first argument to @managed_client and must be a managed client'
      it 'has 2nd argument be the @process_name'

      context 'options hash' do 
        it 'accepts :arguments'
        it 'accepts :while_condition'
        it 'accepts :response_callback'
      end
    end
  end



  context 'public methods' do 
    describe '#client' do 
      it 'should return client instance'
    end

    describe '#set_client' do 
      it 'should change client'
    end

    describe 'latest_body' do 
      it 'should return .body of latest response'
    end


    describe 'latest_response?' do 
      it 'is true if .body exists'
      it 'is false if no .body exists'
    end


    describe '#proceed!' do
      it 'should increment @iterations' 
      it 'should perform @response_callback'
    end
  end

end