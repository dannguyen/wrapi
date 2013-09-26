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
      "Content: 200"
    end
  end


  def time_elapsed
    Time.now.to_i - @last_call_timestamp.to_i 
  end

  def ready_for_call?
    time_elapsed >= @seconds_to_wait_before_next_call
  end

  def seconds_until_next_call
    @seconds_to_wait_before_next_call == 0 ? 0 : time_elapsed - @seconds_to_wait_before_next_call
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

  def register_error_handling
    register_error_handler( TimedClient::NotEnoughTimeElapsed) do |fetch_process, manager|

      # replace client
      if new_client = manager.next_client(fetch_process.client)
        fetch_process.set_client(new_client)
        return true
      else
        return false
      end
    end
  end



end



module Wrapi
  describe 'Wrangler end-to-end with TimedClient' do 

    before(:each) do 
      @wrangler = TimedWrangler.new 
      @client_a = TimedClient.new(wait: 100)
      @client_b = TimedClient.new(wait: 100)
    end

    describe 'client handling' do 
      
      it 'should #add_clients via @manager' do 
         expect(@wrangler.has_clients?).to be_false
        @wrangler.add_clients([@client_a, @client_b])
        expect(@wrangler.has_clients?).to be_true
      end

    end

  end
end



