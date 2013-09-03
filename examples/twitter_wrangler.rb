require 'json'
require 'twitter'
require 'hashie'
require 'andand'

require_relative '../lib/wrapi'

## example usage
=begin
require './examples/twitter_wrangler'
t = TwitterWrangler.init_clients

tweets = []
t.fetch_batch_user_timeline( 'dancow' ) do |resp|
  resp.on_success do |body|
    tweets += body
  end
end


follower_ids = []
t.fetch_batch_follower_ids( 'dancow' ) do |resp|
  resp.on_success do |body|
    follower_ids += body.collection
  end
end


users = []
t.fetch_batch_users(['dancow', 'skift', 'rafat'], 2, {}) do |resp|
  resp.on_success do |body|
    users += body 
  end
end

=end


class TwitterWrangler
  include Wrapi::Wrangler



  # Public: Maximum Twitter ID (as of 2013)...any bigger and Twitter API will reject it as invalid
  
  # Examples:
  #
  #   MAX_TWEET_ID is:                    9000000000000000000
  #   id of current tweet from firehose:  380000000000000000
  MAX_TWEET_ID = (10**18) * 9
 
  # Public: Twitter API allows for 100 user profiles to be retrieved at a time
  MAX_SIZE_OF_USERS_BATCH = 100

################# SINGLE OPERATIONS


  # Public: fetch a user profile given a single user.id or screen_name
  # Technically, delegates to #fetch_batch_users, but returns a Twitter::User
  # The implementation is strange because fetch_batch_users is strange
  # https://dev.twitter.com/docs/api/1.1/get/users/show
  #
  # id            -  a user id or screen_name (Fixnum or String)
  # twitter_opts  -  the only option here is :include_entities
  #
  # Examples 
  #
  #   wrangler.fetch_user('dancow')
  #   #=> #<Twitter::User:0x007fda81211958
  #
  #   wrangler.fetch_user(777)
  #
  #
  # Returns a Twitter::User with the given :id
  # or returns nil if no user is found (TODO)
  def fetch_user(id, twitter_opts={}) 
    arr = [] 
    fetch_batch_users(id, 1, twitter_opts) do |resp|
      arr += resp.body 
    end
  
    return arr.first
  end

  # Public: fetch the information for one list
  #
  # Returns a Twitter::List
  def fetch_list_with_owner_name_and_list_slug(owner_name, list_slug)
    fetch_single(:list, arguments: [owner_name, list_slug])
  end



  ################# BATCH OPERATIONS
  #################


  # Public: fetch an array of user profiles given an array of user ids or screen_names
  # note: this is actually a unitary operation, in that the batching (breaking up the array)
  #   is done by the method, and then passed into twitter's API with the :users call
  #
  # ids           -    twitter user ids or screen_names (Array)
  # batch_size    -    number of users to retrieve each batch (default:  MAX_SIZE_OF_USERS_BATCH).
  # twitter_opts  -    Hash of options: 
  #                        :include_entities
  #
  # Yields a FetchedResponse object from each API call. The body of the object is an array of
  #  Twitter::User objects
  #
  # Examples
  # 
  #    fetch_batch_users(['dan', 'james', 'bob']) do |resp|
  #       arr += resp.body
  #    end
  #
  # Returns an empty array (TODO: May return array of call data)
  #
  # TODO: Handle the error for Twitter::Error::NotFound: Sorry, that page does not exist
  # this occurs when only a single id is passed in and user does not exist
  #
  # TODO: When all the ids are invalid, the response should be an empty array

  def fetch_batch_users(ids, batch_size = nil, twitter_opts = {}, &blk)
    arr_ids = Array(ids)
    batch_size = MAX_SIZE_OF_USERS_BATCH if batch_size.to_i < 1

    twitter_options = Hashie::Mash.new(twitter_opts)

    ## note that this is making multiple unitary calls to the API
    ## which technically breaks the fetch_batch convention and may have implications
    ## in terms of bubbling up exceptions

    # for reference sake only
    total_slices_count = (arr_ids.count/batch_size.to_f).ceil

    arr_ids.each_slice(batch_size).each_with_index do |slice_of_ids, idx|
      puts "On batch #{idx}/#{total_slices_count}"
      fetch(:users, {arguments: [slice_of_ids, twitter_options]}, &blk)
    end
  end





  def fetch_batch_user_timeline(user_id, count=MAX_SIZE_OF_USERS_BATCH, twitter_opts={}, &blk)

    twitter_options = Hashie::Mash.new(twitter_opts).tap do |o|
      o[:count] ||= 200
      o[:include_rts] ||= true 
      o[:trim_user] ||= true 
      o[:since_id] ||= 1 
      o[:max_id] ||= MAX_TWEET_ID
    end

    while_cond = ->(loop_state, args){ 
      o = args[1]

      o[:max_id] > o[:since_id]
    }

    resp_callback = ->(loop_state, args){
      o = args[1]
      if tweets_array = loop_state.latest_body
        o[:max_id] =  tweets_array.last.andand.id.to_i - 1
      end

      puts "max_id: #{o.max_id}\t since_id: #{o.since_id}"
    }



    @manager.fetch_batch(:user_timeline, 
                          arguments: [user_id, twitter_options],    
                          while_condition: while_cond, 
                          response_callback: resp_callback, &blk) 

  end


  def fetch_batch_follower_ids(user_id, twitter_opts={}, &blk)
    manager_args = Hashie::Mash.new 
    manager_args[:arguments] = [user_id] 
    manager_args[:arguments] << Hashie::Mash.new(twitter_opts).tap{ |o|
      o[:cursor] ||= - 1
    }

    manager_args[:while_condition] = ->(loop_state, args){ args[1][:cursor] != 0 }
    manager_args[:response_callback] = ->(loop_state, args){ 
      puts "next cursor: #{args[1][:cursor]}"
      args[1][:cursor] = loop_state.latest_body.next_cursor  
    }

    fetch_batch(:follower_ids, manager_args, &blk)
  end


  # Public: Fetch the lists that a user is a member of
  def fetch_batch_memberships(user_id, twitter_opts={}, &blk)
    manager_args = Hashie::Mash.new 
    manager_args[:arguments] = [user_id]
    manager_args[:arguments] << Hashie::Mash.new(twitter_opts).tap{|t| t[:cursor] ||= -1 }

    manager_args[:while_condition] = ->(loop_state, args){ args[1][:cursor] != 0 }
    manager_args[:response_callback] = ->(loop_state, args){ 
      puts "next cursor: #{args[1][:cursor]}"
      args[1][:cursor] = loop_state.latest_body.next_cursor  
    }

    fetch_batch(:memberships, manager_args, &blk)
  end


  # Public: Fetch the members of a list
  def fetch_batch_list_members(list_id, twitter_opts={}, &blk)
    manager_args = Hashie::Mash.new 
    manager_args[:arguments] = []
    manager_args[:arguments] << Hashie::Mash.new(twitter_opts).tap{ |t| 
      t[:list_id] = list_id
      t[:cursor] ||= -1 
      t[:skip_status] ||= false
    }

    manager_args[:while_condition] = ->(loop_state, args){ args[1][:cursor] != 0 }
    manager_args[:response_callback] = ->(loop_state, args){ 
      puts "next cursor: #{args[1][:cursor]}"
      args[1][:cursor] = loop_state.latest_body.next_cursor  
    }

    fetch_batch(:list_members, manager_args, &blk)
  end



#################################
#### Error handling


#  handle_error Twitter::Error::NotFound 

#  end



#################################
#### Initialization stuff

  # return an instantiated client
  def initialize_client(cred)
    Twitter::Client.new(cred)
  end

  # map loaded_creds into an array
  def parse_credentials(loaded_creds)
    arr = []
    loaded_creds.each do |creds|
      app_hash = creds.dup.keep_if{|k,v| ['consumer_key', 'consumer_secret'].include?(k)}

      arr += creds['tokens'].map{ |token|  token.merge(app_hash).symbolize_keys }
    end

    return arr
  end

  # in this case, the object is an array of objects, each of which contains an array of :tokens
  def load_credentials()
    JSON.parse open( File.expand_path('../twitter-creds.json', __FILE__) ){|f| f.read}
  end
end



=begin
  define_rate_errors(Twitter::RateLimit, Twitter::Something) do |manager, error|

    manager.remove_client(client)
    manager.find_new_client

    true
  end

=end

