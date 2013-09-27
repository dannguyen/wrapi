require 'spec_helper'


describe 'delegation' do 

  before(:each) do 
    @client = double()
    @client.stub(:foo){ 'Hello' }
    @client.stub(:class){ 'Yappi'}
    @client.stub(:bad_foo){ raise StandardError, 'Bad!'}
    @managed_client = ManagedClient.new @client
  end


  it 'should expose #bare_client' do 
    expect(@managed_client.bare_client.class.to_s).to eq 'Yappi'
  end

  it 'should delegate specific call' do 
    expect(@client).to receive(:foo)
    @managed_client.send_fetch_call :foo
  end

  it 'should keep @latest_call_timestamp' do 
    t = Time.now
    @managed_client.send_fetch_call :foo
    Timecop.travel(Time.now + 1000)

    expect(@managed_client.latest_call_timestamp).to be_within(1001).of Time.now
  end

  it 'should count #seconds_elapsed_since_latest_call' do 
    @managed_client.send_fetch_call :foo
    Timecop.travel(Time.now + 10000)
    expect(@managed_client.seconds_elapsed_since_latest_call).to be_within(2).of(10000)
  end

  it 'should track call count' do 
    @managed_client.send_fetch_call :foo
    @managed_client.send_fetch_call :foo

    expect(@managed_client.call_count).to eq 2
  end

  it 'should track error_count and successful_call_count' do 
    @managed_client.send_fetch_call :foo
    begin
      @managed_client.send_fetch_call :bad_foo
    rescue => err 
      # do nothing
    end

    expect(@managed_client.error_count).to eq 1
    expect(@managed_client.successful_call_count).to eq 1
    expect(@managed_client.call_count).to eq 2
  end

end