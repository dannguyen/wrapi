require 'json'
require 'twitter'
require 'hashie'
require 'andand'

require_relative '../lib/wrapi'

## example usage
# require './examples/twitter_wrangler'
# t = TwitterWrangler.init_clients
# arr = []
# t.fetch_batch_user_timeline( 'dancow' ) do |resp|
#  resp.on_success do |body|
#    arr += body
#  end
# end



class TwitterWrangler
  include Wrapi::Wrangler

  MAX_TWEET_ID = (10**18) * 9
  

  def fetch_batch_user_timeline(user_id, twitter_opts={}, &blk)

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
      if tweets_array = loop_state.latest_response.body
        o[:max_id] =  tweets_array.last.andand.id.to_i - 1
      end

      puts "max_id: #{o.max_id}\t since_id: #{o.since_id}"
    }



    @manager.fetch_batch(:user_timeline, 
                          arguments: [user_id, twitter_options],    
                          while_condition: while_cond, 
                          response_callback: resp_callback, &blk) 

  end


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

