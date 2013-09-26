# end to end testing with a TimedClient
require 'spec_helper'

class TimedClient
  def initialize(config={})
    @last_call_timestamp = nil
    @calls_made = 0

    @seconds_to_wait_before_next_call = config[:wait] || 0
  end

  def call_api
    if !ready_for_call?
      raise NotEnoughTimeElapsed, "Must wait #{seconds_until_next_call}"
    else
      @last_call_timestamp = Time.now
      @calls_made += 1
      body = "Content: 200; Call count: #{@calls_made}"
    end

    return body
  end


  def time_elapsed
    Time.now.to_i - @last_call_timestamp.to_i 
  end

  def ready_for_call?
    time_elapsed >= @seconds_to_wait_before_next_call
  end

  def seconds_until_next_call
    @seconds_to_wait_before_next_call == 0 ? 0 :  @seconds_to_wait_before_next_call - time_elapsed
  end

  class NotEnoughTimeElapsed < StandardError; end
end


class TimedWrangler 
  include Wrapi::Wrangler
=begin
   # return an instantiated client
  def initialize_client(config={})
    TimedClient.new(config)
  end

  # map loaded_creds into an array
  def parse_credentials(loaded_creds)
    return loaded_creds
  end

  # in this case, the object is an array of objects, each of which contains an array of :tokens
  def load_credentials()
    []
  end
=end  

  def fetch_single_api 
    fetch_single(:call_api) 
  end

  def register_error_handling
    register_error_handler( TimedClient::NotEnoughTimeElapsed) do |fetch_process, manager|
      # replace client
      new_client = manager.find_next_client(fetch_process.client){|c| c.ready_for_call? }
      # true or false
      return_boolean_val = case 
      when new_client
        fetch_process.set_client(new_client)
        true
      else
        false
      end

      return_boolean_val
    end
  end



end



module Wrapi
  describe 'Wrangler end-to-end with TimedClient' do 

    before(:each) do 
      @wrangler = TimedWrangler.new 
      @client_a = TimedClient.new(wait: 1000)
      @client_b = TimedClient.new(wait: 1000)
    end

    describe 'client handling' do 
      it 'should #add_clients via @manager' do 
         expect(@wrangler.has_clients?).to be_false
        @wrangler.add_clients([@client_a, @client_b])
        expect(@wrangler.has_clients?).to be_true
      end
    end

    describe 'rate-limited error with one client' do 
      before(:each) do 
        @wrangler.add_clients(@client_a)
      end

      it 'should succeed on first attempt' do  
        expect(@wrangler.fetch_single_api).to eq "Content: 200; Call count: 1"
      end

      it 'should fail on second attempt' do 
        @wrangler.fetch_single_api
        expect{ @wrangler.fetch_single_api }.to raise_error TimedClient::NotEnoughTimeElapsed
      end

      it 'should succeed after enough time is waited' do 
        @wrangler.fetch_single_api
        Timecop.travel(Time.now + 900)
        expect{ @wrangler.fetch_single_api }.to raise_error TimedClient::NotEnoughTimeElapsed
        # just wait a little longer...
        Timecop.travel(Time.now + 100)

        expect(@wrangler.fetch_single_api).to eq "Content: 200; Call count: 2"
      end

    end
  end
end



