require 'spec_helper'

describe "Wrapi::Manager" do
  it "true" do
    expect(true).to be_true
  end


  context 'pool management' do 

  end

  context 'batch calls' do 

    it 'should quit after lambda condition is reached'
    it 'should allow specification of one single client'

    context 'rate limit denials' do 
      it 'should punt to next client'

    end

  end

  # even singular calls should have rate limiting
  #
  # when a singular call fails, manager has number of retries
  context 'singular calls' do 

  end


end
