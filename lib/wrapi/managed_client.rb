require 'delegate'
require_relative 'error_collector'

module Wrapi
  class ManagedClient < SimpleDelegator

    attr_reader :latest_call_timestamp, :call_count


    include Wrapi::ErrorCollector
    # nil out several non-used methods
    def clear_error!; puts "Warning, not supposed to be invoked for ManagedClient"; nil; end
    def unfixed_error!; puts "Warning, not supposed to be invoked for ManagedClient"; nil; end
    ###


    def initialize(client)
      @client = client 
      @call_count = 0

      super(@client)
    end


    def bare_client
      @client 
    end

    def is_managed?
      true # just to keep this from being delegated to @client
    end

    def successful_call_count
      @call_count - error_count
    end

    def seconds_elapsed_since_latest_call
      Time.now.to_i - @latest_call_timestamp.to_i 
    end



    def send_fetch_call(process_name, *arguments )
      before_call
      begin
        resp = @client.send process_name, *arguments
      rescue => err 
        log_error(err)
        raise err
      else

        return resp
      end
    end

    private

    def before_call
      @latest_call_timestamp = Time.now 
      @call_count += 1
    end

  end
end