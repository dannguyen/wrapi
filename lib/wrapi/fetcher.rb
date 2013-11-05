require_relative 'client_queue'
require_relative 'managed_client'
require_relative 'fetch_process'

module Wrapi
  class Fetcher
                      

    attr_reader :error_handlers

    # queue methods
    delegate :clients, :find_client, :remove_client, 
                      :bare_clients, :find_next_client, 
                      :has_clients?,
            {:to => :@queue}

    # current process information
    delegate :client, :iteration_count, :latest_response, 
          {:to => :current_process, prefix: true, allow_nil: true}


    def initialize(opts={})
      # by default, shuffle the clients before each fetch call
      @shuffle_before_fetch = opts[:shuffle] == false ? false : true

      @queue = ClientQueue.new
      @error_handlers = Hash.new
      @fetch_process = nil
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

    def shuffle_clients_before_fetch?
      @shuffle_before_fetch
    end

    # untested
    def shuffle_clients!
      @queue.shuffle!
    end


    def current_process
      @fetch_process
    end



    # def current_process_client
    #   @fetch_process.client if has_process?
    # end

    def has_process?
      !current_process.nil?
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



    # Public: used in the common situation in which the @fetch_process's client 
    #         needs to be switched out to a new one. 
    #
    # old_client(ManagedClient): This is optional. By default, it is the current @fetch_process
    #                            client 
    #
    # returns true/false, so that it can meet the FetchProcess requirement that
    #     error handling methods return true or false

    def switch_to_new_client!(old_client = current_process_client, &blk)
      puts "Old client is: #{old_client}"
      new_client = self.find_next_client(old_client, &blk)
      unless new_client.nil?
        puts "New client is #{new_client}"
        @fetch_process.set_client(new_client)
        return true 
      else
        return false
      end
    end



    def fetch(foo_name, opts={}, fetch_mode=:single, &callback_on_response_object)
      raise ArgumentError, "Second argument must be Hash, not #{opts.class}" unless opts.is_a?(Hash)

      # shuffle clients here, TK: codesmell
      if shuffle_clients_before_fetch?
        shuffle_clients!
      end

      client = find_client

      @fetch_process = case fetch_mode.to_s
      when /batch/
         BatchFetchProcess.new(client, foo_name, Hashie::Mash.new(opts))
      else
         SingularFetchProcess.new(client, foo_name, Hashie::Mash.new(opts))
      end

      array_of_bodies = []

      while @fetch_process.ready_to_execute? 
        # expecting FetchResponse object
        @fetch_process.execute do |response|
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
            @fetch_process.proceed!            
          end



          # Error handling
          response.on_error do 
            # if there was a block, yield it to the Wrangler 
            if callback_on_response_object
              yield response 
            end
              

            # set a state variable
            is_error_resolved = false

            ## note: error_handling_proc MUST return true or false
            ## or else @fetch_process will raise an error
            if error_handling_proc = get_error_handler(response.error)
              # to the registered error handling process, 
              # we pass the current @fetch_process and self(Fetcher)
              #
              # fix_error returns true or false
              is_error_resolved = @fetch_process.fix_error do 
                error_handling_proc.call(self, response.error )
              end
            end

            unless is_error_resolved
              # if no error handler found, or @fetch_process.fix_error returned false,
              #   then raise the error
              raise response.error   
            end
          end # of response.on_error

        end
      end# end of while loop

      return array_of_bodies # this is empty if block was given
    end



    # same as fetch, but enforces the existence of a block
    def fetch_batch(client_foo, opts, &blk)
      raise ArgumentError, "Block is expected for batch call" unless block_given?
      fetch(client_foo, opts, :batch, &blk)
    end


    # same as fetch, but unwraps the usual returned array of FetchedResponses
    # and returns only the body of the first element
    # Obviously, you're expecting only a single call and response here
    # e.g. fetch_single_tweet(id: 10101099 )
    #
    # unlike batch, will return f_Response as well as yielding to a block
    def fetch_single(client_foo, opts={}, &blk)
      f_response = nil
      fetch(client_foo, opts, :single) do |resp|
        f_response = resp

        yield f_response if block_given?
      end

      return f_response
    end

    # UNTESTED: ad-hoc replacement for fetch_single, which now accepts a block
    # raises error if block is given
    # returns just the body
    def fetch_simple(client_foo, opts={})
      raise ArgumentError, "Block is not expected for simple call" if block_given?
      arr = fetch(client_foo, opts, :single)

      return arr.first.body
    end

  end
end
