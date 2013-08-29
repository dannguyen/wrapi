require 'spec_helper'


describe 'delegation' do 

  before(:each) do 
    @client = double()
    @client.stub(:call_the_api){ 'Hello' }
    @client.stub(:class){ 'Yappi'}
    @managed_client = ManagedClient.new @client
  end


  it 'should expose #bare_client' do 
    expect(@managed_client.bare_client.class.to_s).to eq 'Yappi'
  end

  it 'should delegate specific call' do 
    expect(@client).to receive(:call_the_api)
    @managed_client.call_the_api
  end

end