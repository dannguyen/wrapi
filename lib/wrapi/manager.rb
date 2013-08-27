require_relative 'client_pool'
require_relative 'managed_client'


module Wrapi
  class Manager


    def initialize
      @pool = ClientPool.new
    end

    def add_clients(arr)
      array = arr.is_a?(Hash) ? [arr] : Array(arr) 

      array.each do |client|
        @pool.add_client ManagedClient.new( client ) 
      end
      
      nil
    end

    def client_count
      @pool.size
    end

    def find_client
      @pool.find_client 
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



      # send the symbol directly to the client, with arguments
      if client_foo.kind_of?(String) || client_foo.kind_of?(Symbol)
        client_lambda = ->(*args){ client.send client_foo, *args }
      end


      while( while_condition.call(loop_state, arguments ) )

        client_lambda.call(*arguments) 

        ## now alter loop state 
        loop_state.iterations += 1
      end

    end


    # same as fetch, but enforces the existence of response_callback and while
    def fetch_batch(client_foo, opts)


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