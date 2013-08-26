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
      @pool.clients.first
    end

    def fetch(client_foo, opts={})


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