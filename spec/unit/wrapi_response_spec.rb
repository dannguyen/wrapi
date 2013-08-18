require 'spec_helper'
class SomeKindOfError < StandardError; end 

describe 'Wrapi::FetchedResponse' do 


  describe 'error subclass' do 

    describe 'factory' do 
      it 'should instantiate via ::error' do 
        expect(FetchedResponse.error StandardError.new).to be_a FetchedResponse
      end

      it 'should take two optional args' do 
        @e = FetchedResponse.error StandardError.new, 'bodystuff'
        expect(@e.body).to eq 'bodystuff'
        expect(@e.error).to be_a StandardError
      end
    end


    before(:each) do 
      @error = SomeKindOfError.new("Sup")
      @errored = FetchedResponse.error(@error, 'body')
    end


    describe 'attributes' do 

      it 'should be #error?' do 
        expect(@errored.error?).to be_true
      end

      it 'should have #error set' do 
        expect(@errored.error).to eq @error
      end

      it 'should not be a #success?' do 
        expect(@errored.success?).to be_false
      end      
    end

    describe '#on_error' do 
      it 'should yield two arguments' do 
        expect{ |b|  @errored.on_error(&b) }.to yield_with_args(@error, 'body')
      end

      it 'should not yield on_success' do 
        expect{ |b| @errored.on_success(&b) }.not_to yield_control
      end
    end
  end

end