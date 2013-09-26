require_relative 'client_queue'
require_relative 'managed_client'
require_relative 'fetch_process'

module Wrapi
  class Manager
    extend Forwardable
    def_delegators :@queue, 
                      :clients, :find_client, :remove_client, 
                      :bare_clients, :find_next_client

    attr_reader :error_handlers

    def initialize
      @queue = ClientQueue.new
      @error_handlers = Hash.new
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

    # Public: not used
    def shuffle_clients
      @queue.shuffle!
    end

    def fetch(foo_name, opts={}, fetch_mode=:single, &callback_on_response_object)
      raise ArgumentError, "Second argument must be Hash, not #{opts.class}" unless opts.is_a?(Hash)
      client = find_client

      fetch_process = case fetch_mode.to_s
      when /batch/
         BatchFetchProcess.new(client, foo_name, Hashie::Mash.new(opts))
      else
         SingularFetchProcess.new(client, foo_name, Hashie::Mash.new(opts))
      end

      array_of_bodies = []

      while fetch_process.ready_to_execute? 
        # expecting FetchResponse object
        fetch_process.execute do |response|
          response.on_success do
            # if there was a block passed in by the Wrangler, 
            # then yield the response to it
            if callback_on_response_object
              yield response
            else
              # otherwise, stash it into array of bodies
              # NOTE: this may not actually be supported
              array_of_bodies << response
            end

            # on success, move to the next state
            fetch_process.proceed!            
          end



          # Error handling
          response.on_error do 
            # if there was a block, yield it to the Wrangler 
            if callback_on_response_object
              yield response 
            end
              

            # set a state variable
            error_resolved = false

            ## note: error_handling_proc MUST return true or false
            ## or else fetch_process will raise an error
            if error_handling_proc = get_error_handler(response.error)
              # to the registered error handling process, 
              # we pass the current fetch_process and self(Manager)
              #
              # fix_error returns true or false
              error_resolved = fetch_process.fix_error do |_fetch_process|
                error_handling_proc.call(_fetch_process, self)
              end
            end

            unless error_resolved
              # if no error handler found, or fetch_process.fix_error returned false,
              #   then raise the error
              raise response.error   
            end
          end # of response.on_error

        end
      end# end of while loop

      return array_of_bodies # this is empty if block was given
    end


    def register_error_handler(err_klass, proc=nil, &handling_blk)
      if proc.nil? && !block_given?
        raise ArgumentError, "Must either pass in a proc or a handling block"
      end
      proc = proc || handling_blk

      @error_handlers[err_klass] = proc
    end

    # if it is an Error instance, use its klass
    def get_error_handler(err)
      klass = err.is_a?(Class) ? err : err.class

      @error_handlers[klass]
    end

    # same as fetch, but enforces the existence of while_condition
    def fetch_batch(client_foo, opts, &blk)
      fetch(client_foo, opts, :batch, &blk)
    end


    # same as fetch, but unwraps the usual returned array of FetchedResponses
    # and returns only the body of the first element
    # Obviously, you're expecting only a single call and response here
    # e.g. fetch_single_tweet(id: 10101099 )
    #
    # raises error if block is given
    def fetch_single(client_foo, opts={}, &blk)
      raise ArgumentError, "Block is not expected for singular call" if block_given?
      arr = fetch(client_foo, opts, :single)

      return arr.first.body
    end
  end
end
