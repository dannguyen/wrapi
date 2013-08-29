require_relative 'client_queue'
require_relative 'managed_client'


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

    def fetch(client_foo, opts={})
      
      raise ArgumentError, "Second argument must be Hash, not #{opts.class}" unless opts.is_a?(Hash)

      options = Hashie::Mash.new(opts)

      # Setup client and loop_state
      client = find_client
      loop_state = Hashie::Mash.new({iterations: 0})

      # Options parsing
      ################# :arguments
      arguments = opts[:arguments] || []
      # verify :arguments is an array
      raise ArgumentError, ":arguments needs to be an array, not a #{arguments.class}" unless arguments.is_a?(Array)


      ################# :while_condition
      ##
      #  by default, the while condition sees if loop_state is < 1, i.e. executes exactly once
      while_condition = opts[:while_condition] || ->(loop_state, args){ loop_state.iterations < 1 }
      raise ArgumentError, ":while_condition needs to respond to :call" unless while_condition.respond_to?(:call)


      ################# :response_callback
      # must be a lambda with arity of 2
      # args are: loop_state and :arguments
      response_callback = opts[:response_callback] || ->(loop_state, args){  }
      raise ArgumentError, ":response_callback needs to be a Proc with arity == 2" unless response_callback.respond_to?(:call) && response_callback.arity == 2 



      # Now onto the actual execution !!
      #
      ###### send the symbol directly to the client, with arguments
      if client_foo.kind_of?(String) || client_foo.kind_of?(Symbol)
        client_lambda = ->(*args){ client.send client_foo, *args }
      end

      # this is returned as an array of responses if no block is given
      # if a block is given, then this array will be empty
      # This prevents the method from collecting a massive amount of response data that
      # has already been acted upon by a block
      array_of_bodies = []

      # finally, the while loop
      while( while_condition.call(loop_state, arguments ) )

        begin 
          resp_body = client_lambda.call(*arguments) 
        rescue StandardError => err 
          response_object = FetchedResponse.error(err)

        else
          response_object = FetchedResponse.success(resp_body)
              ################# block_given?
            if block_given?
              ### yield the response_object (FetchedResponse) to the block
              yield response_object 
            else 
              array_of_bodies << response_object 
            end 


            ## now alter loop state 
            loop_state.iterations += 1
            loop_state.latest_response = response_object
            loop_state[:latest_response?] = !(response_object.body.nil? && response_body.body.empty?)
            ##

            # hook for wrangler
            response_callback.call(loop_state, arguments)
          end 
        end# end of while loop

      return array_of_bodies # this is empty if block was given
    end


    # same as fetch, but enforces the existence of while_condition
    def fetch_batch(client_foo, opts)

      options = Hashie::Mash.new(opts)
      raise ArgumentError, "Batch operations expect a while condition" unless options[:while_condition]

      fetch(client_foo, opts)
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

=begin

manager.fetch_batch do |client|
  client.send user_timeline

end

def fetch_batch_user_timeline 

  mashie = {}
  manager.fetch_batch(mashie) do |client, state_mash|
    resp = client.user_timeline user_name, mashie
    
    mashie = #

  end

end


fetch( 
  :user_timeline, 

  arguments: ['dancow', {count: 200, include_rts: true, trim_user: true, since_id: 1, max_id: 999} ], 

  response_callback: ->(response_body, args){
    mash = args[1]
    mash[:max_id] = response_body.last.andand.id.to_i - 1
  },

  while_condition: ->(loop_state, args){ 
    mash = args[1]   

    mash.max_id > mash.since_id
  },

  yield_to: blk

)



fetch(
  :get_connections,
  :arguments => [facebook_id, :feed, facebook_opts],
  :do_while => true,  # or something?

  :response_callback: ->(response_body, args){
    response_body = response_body.next_page
  }, 
  :while_condition => ->(loop_state, args){
    loop_state.last_response.present?
  }, 
)
=end