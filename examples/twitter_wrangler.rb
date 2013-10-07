require 'json'
require 'twitter'
require 'hashie'
require 'andand'

require 'active_support/core_ext/hash/slice'

require_relative '../lib/wrapi'


class TwitterWrangler
  include Wrapi::Wrangler

  # Public: Maximum Twitter ID (as of 2013)...any bigger and Twitter API will reject it as invalid
    # not sure why (2**63)-1 is rejected, as that's a 64 bit integer. This works fine for now.
  # Examples:
  #
  #   MAX_TWEET_ID is:                    4611686018427387904
  #   id of current tweet from firehose:   380000000000000000
  MAX_TWEET_ID = (2**62) - 1
 
  # Public: Twitter API allows for 100 user profiles to be retrieved at a time
  MAX_SIZE_OF_USERS_BATCH = 100

  MAX_COUNT_OF_TWEETS_BATCH = 200

  DEFAULT_QUERIES = {
    :user_timeline => {
      count: MAX_COUNT_OF_TWEETS_BATCH,
      include_rts: true,
      trim_user: true, 
      since_id: 1, 
      max_id: MAX_TWEET_ID
    } 
  }


#################################
#### Initialization stuff

  # return an instantiated client
  def initialize_client(cred)
    Twitter::REST::Client.new(cred)
  end

  # map loaded_creds into an array
  def parse_credentials(loaded_creds)
    arr = []
    loaded_creds.each do |creds|
      app_hash = creds.dup.slice('consumer_key', 'consumer_secret') 
      arr += creds['tokens'].map do |token|  
        oauth_token = token.slice('oauth_token', 'oauth_token_secret')
       
        oauth_token.merge(app_hash).symbolize_keys
      end 
    end

    return arr
  end

  # in this case, the object is an array of objects, each of which contains an array of :tokens
  def load_credentials()
    JSON.parse open( File.expand_path('../creds/twitter-creds.json', __FILE__) ){|f| f.read}
  end


  def register_error_handlers
    register_error_handler( Twitter::Error::TooManyRequests ) do |_fetcher, error|

      # get failed method at hand
      current_erred_process = error.wrapi_data.process_name


      _fetcher.switch_to_new_client! do |c| 
        # find any client in which rate_limit is within 

        # see if this client has any of the same error
#        errors = c.errors_by_kind(error.class).find{|e| e.wrapi_data.process_name == current_erred_process }
        
        # see if any of those errors have 
#        errors.current_erred_process

#        c.errors_collection.any?{ |e| e == }   

        ### STUB TK
        true
      end


    end
  end




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
    opts = prepare_fetcher_options
    opts[:arguments] = [owner_name, list_slug]

    fetch_single(:list, opts)
  end



  ################# BATCH OPERATIONS
  #################


  # Public: fetch an array of user profiles given an array of user ids or screen_names
  # note: this is actually a singular operation, in that the batching (breaking up the array)
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

    default_args = prepare_fetcher_options

    # for reference sake only
    total_slices_count = (arr_ids.count/batch_size.to_f).ceil

    arr_ids.each_slice(batch_size).each_with_index do |slice_of_ids, idx|
      puts "On batch #{idx}/#{total_slices_count}"
      fetcher_opts = default_args.merge({arguments: [slice_of_ids, twitter_options]})
      fetch(:users, fetcher_opts, &blk)
    end
  end


  def fetch_batch_user_timeline(user_id, twitter_opts={}, &blk)

    fetch_options = prepare_fetcher_options

    opts = Hashie::Mash.new(twitter_opts).tap do |o|
      # tk: refactor
      DEFAULT_QUERIES[:user_timeline].each_pair do |d_key, d_value|
        o[d_key] ||= d_value
      end
    end

    fetch_options[:arguments] = [user_id, opts]

    fetch_options[:while_condition] = ->(loop_state, args) do 
      o = args[1]
      o[:max_id] > o[:since_id]
    end

    fetch_options[:response_callback] = ->(loop_state, args) do 
      opts = args[1]
      if tweets_array = loop_state.latest_body
        opts[:max_id] =  tweets_array.last.andand.id.to_i - 1
      end

      puts "max_id: #{opts.max_id}\t since_id: #{opts.since_id}"
    end

    @fetcher.fetch_batch(:user_timeline, fetch_options, &blk) 
  end


  def fetch_batch_user_timeline(user_id, twitter_opts={}, &blk)
    fetch_options = {}

    opts = Hashie::Mash.new(twitter_opts).tap do |o|
      o[:count] ||= MAX_COUNT_OF_TWEETS_BATCH
      o[:include_rts] ||= true 
      o[:trim_user] ||= true 
      o[:since_id] ||= 1 
      o[:max_id] ||= MAX_TWEET_ID
    end

    fetch_options[:arguments] = [user_id, opts]

    fetch_options[:while_condition] = ->(loop_state, args) do 
      o = args[1]
      o[:max_id] > o[:since_id]
    end

    fetch_options[:response_callback] = ->(loop_state, args) do 
      opts = args[1]
      if tweets_array = loop_state.latest_body
        opts[:max_id] =  tweets_array.last.andand.id.to_i - 1
      end

#      puts "max_id: #{opts.max_id}\t since_id: #{opts.since_id}"
    end




    @fetcher.fetch_batch(:user_timeline, fetch_options, &blk) 
  end


  def fetch_batch_follower_ids(user_id, twitter_opts={}, &blk)
    fetcher_opts = prepare_fetcher_options
    fetcher_opts[:arguments] = [user_id] 
    fetcher_opts[:arguments] << Hashie::Mash.new(twitter_opts).tap{ |o|
      o[:cursor] ||= - 1
    }

    fetcher_opts[:while_condition] = ->(loop_state, args){ args[1][:cursor] != 0 }
    fetcher_opts[:response_callback] = ->(loop_state, args){ 
      puts "next cursor: #{args[1][:cursor]}"
      args[1][:cursor] = loop_state.latest_body.next_cursor  
    }

    fetch_batch(:follower_ids, fetcher_opts, &blk)
  end


  # Public: Fetch the lists that a user is a member of
  def fetch_batch_memberships(user_id, twitter_opts={}, &blk)
    fetcher_opts = prepare_fetcher_options
    fetcher_opts[:arguments] = [user_id]
    fetcher_opts[:arguments] << Hashie::Mash.new(twitter_opts).tap{|t| t[:cursor] ||= -1 }

    fetcher_opts[:while_condition] = ->(loop_state, args){ args[1][:cursor] != 0 }
    fetcher_opts[:response_callback] = ->(loop_state, args){ 
      puts "next cursor: #{args[1][:cursor]}"
      args[1][:cursor] = loop_state.latest_body.next_cursor  
    }

    fetch_batch(:memberships, fetcher_opts, &blk)
  end


  # Public: Fetch the members of a list
  def fetch_batch_list_members(list_id, twitter_opts={}, &blk)
    fetcher_opts = prepare_fetcher_options
    fetcher_opts[:arguments] = []
    fetcher_opts[:arguments] << Hashie::Mash.new(twitter_opts).tap{ |t| 
      t[:list_id] = list_id
      t[:cursor] ||= -1 
      t[:skip_status] ||= false
    }

    fetcher_opts[:while_condition] = ->(loop_state, args){ args[1][:cursor] != 0 }
    fetcher_opts[:response_callback] = ->(loop_state, args){ 
      puts "next cursor: #{args[1][:cursor]}"
      args[1][:cursor] = loop_state.latest_body.next_cursor  
    }

    fetch_batch(:list_members, fetcher_opts, &blk)
  end



# # from api_fetchee

#     def determine_rate_limit_timestamp
#        if error_object.is_a?(Twitter::Error::TooManyRequests)
#           # Twitter::Error::TooManyRequests has a .rate_limit method
#           x_seconds = error_object.rate_limit.attrs["x-rate-limit-reset"].to_i
#           return Time.at x_seconds
#        else # 
#           return Time.now + DEFAULT_TIMEOUT_SECONDS 
#        end
#     end

end







##############################################################
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


# generate fixture data


fdir = "./"
max_iteration_count = 5
_x = 0

max_id = 383969384785805311
t.fetch_batch_user_timeline( 'USAgov',  {count: 1 , max_id: max_id}  ) do |resp|  
  tweets_array = resp.body
   # _max_id =  tweets_array.last.andand.id.to_i - 1
   fname = "#{max_id}.json" # save the max_id that resulted in this
   
   fpath = File.join(fdir, fname)
   puts fpath
   File.write(fpath, tweets_array.to_json)
  
  max_id =  tweets_array.last.andand.id.to_i - 1
  _x += 1 

  break if _x > max_iteration_count

end




follower_ids = []
t.fetch_batch_follower_ids( 'dancow' ) do |resp|
  resp.on_success do |body|
    follower_ids += body.to_a
  end
end


users = []
t.fetch_batch_users(['dancow', 'skift', 'rafat'], 2, {}) do |resp|
  resp.on_success do |body|
    users += body 
  end
end

=end


