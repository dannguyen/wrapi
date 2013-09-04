require_relative 'client_queue'
require_relative 'managed_client'
require_relative 'fetch_process'

module Wrapi
  class Manager
    extend Forwardable
    def_delegators :@queue, :find_client, :remove_client, :bare_clients, :clients

    def initialize
      @queue = ClientQueue.new
    end

    def add_clients(arr)
      array = arr.is_a?(Hash) ? [arr] : Array(arr) 

      array.each do |client|
        @queue.add_client ManagedClient.new( client ) 
      end
      
      nil
    end

    def client_count
      @queue.size
    end

    def has_clients?
      client_count > 0
    end
   
    def shuffle_clients
      @queue.shuffle!
    end

    def fetch(foo_name, opts={}, &callback_on_response_object)
      raise ArgumentError, "Second argument must be Hash, not #{opts.class}" unless opts.is_a?(Hash)
      

      client = find_client

      fetch_process = FetchProcess.new(client, foo_name, Hashie::Mash.new(opts))

      array_of_bodies = []

      while fetch_process.while_condition? 
        # expecting FetchResponse object
        fetch_process.execute do |response|

          response.on_success do
            if callback_on_response_object
              yield response
            else
              array_of_bodies << response
            end

            # on success, move to the next state
            fetch_process.proceed!            
          end

          response.on_error do 
            #### this is where error handling goes...?
            if callback_on_response_object
              yield response 
            else
              raise response.error 
            end
          end
        end
      end# end of while loop

      return array_of_bodies # this is empty if block was given
    end



    # same as fetch, but enforces the existence of while_condition
    def fetch_batch(client_foo, opts, &blk)

      # todo: should be handled in FetchProcess.factory
      options = Hashie::Mash.new(opts)
      raise ArgumentError, "Batch operations expect a while condition" unless options[:while_condition]

      fetch(client_foo, opts, &blk)
    end


    # same as fetch, but unwraps the usual returned array of FetchedResponses
    # and returns only the body of the first element
    # Obviously, you're expecting only a single call and response here
    # e.g. fetch_single_tweet(id: 10101099 )
    #
    # raises error if block is given
    def fetch_single(client_foo, opts={})
      raise ArgumentError, "Block is not expected for singular call" if block_given?
      arr = fetch(client_foo, opts)

      return arr.first.body
    end


  end
end
