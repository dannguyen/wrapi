# end to end testing with a TimedClient
require 'spec_helper'
module Wrapi
  describe 'Wrangler end-to-end with TimedClient' do    
    describe 'client handling' do 
      it 'should #add_clients via @manager' do 
        wrangler = TimedWrangler.new
        expect(wrangler.has_clients?).to be_false
        wrangler.add_clients([TimedClient.new, TimedClient.new])

        expect(wrangler.has_clients?).to be_true
      end
    end

    context 'single fetches' do 
       before(:each) do 
        @wrangler = TimedWrangler.new 
        @client_a = TimedClient.new(wait: 1000)
        @client_b = TimedClient.new(wait: 1000)
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

      describe 'rate-limited errors with two clients' do 
        before(:each) do 
          @wrangler.add_clients([@client_a, @client_b])
        end

        it 'should automatically switch to second client' do 
          @wrangler.fetch_single_api
          # second client should only have been called once
          expect(@wrangler.fetch_single_api).to eq "Content: 200; Call count: 1"
        end

        it 'should bubble error up if no more clients' do 
          @wrangler.fetch_single_api
          @wrangler.fetch_single_api
          expect{ @wrangler.fetch_single_api }.to raise_error TimedClient::NotEnoughTimeElapsed
        end

        it 'should move to valid client after some time' do 
          @wrangler.fetch_single_api
          Timecop.travel(Time.now + 900)
          @wrangler.fetch_single_api
          Timecop.travel(Time.now + 900)

          expect(@wrangler.fetch_single_api).to eq "Content: 200; Call count: 2"
        end
      end

    end # single fetches


    # this is more or less a very end to end test
    context 'batch fetches' do 
       before(:each) do 
        @wrangler = TimedWrangler.new 
        @wrangler.register_error_handler TimedClient::NotEnoughTimeElapsed do |f,m|
                                            client = f.client 
                                            sec = client.seconds_until_next_call
                                            # basically this is a sleep command
                                            Timecop.travel(sec + 1)

                                            client.ready_for_call?
                                          end

        
       end 



       it 'should do the sleeping and quit after while_condition is false' do 
          start_time = Time.now
          resp_array = []

          @wrangler.add_clients TimedClient.new( wait: 100 )
          @wrangler.fetch_batch(:call_api, 
             while_condition: ->(fetch_process, args){ fetch_process.iterations < 3 }
          )   do  |resp|
            resp_array << resp.body
          end

          # should execute 3 times
          expect(resp_array.last).to eq "Content: 200; Call count: 3"
          expect(Time.now - start_time).to be_within(5).of(100 * 2)
       end




     end # batch fetches

  end
end







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

  def fetch_single_api 
    fetch_single(:call_api) 
  end

  def register_error_handling
    register_error_handler( TimedClient::NotEnoughTimeElapsed) do |fetch_process, manager|
      # replace client
      new_client =  manager.find_next_client(fetch_process.client){|c| c.ready_for_call? }
      # true or false
      boolean_to_return = case 
      when new_client
        fetch_process.set_client(new_client)
        true
      else
        false
      end


      boolean_to_return
    end
  end
end



