require 'json'
require 'twitter'

require_relative '../lib/wrapi'

class TwitterWrangler
  include Wrapi::Wrangler

=begin
  define_rate_errors(Twitter::RateLimit, Twitter::Something) do |manager, error|

    manager.remove_client(client)
    manager.find_new_client

    true
  end

=end


  def fetch_batch_user_timeline(user_id, twitter_opts={}, &blk)
    manager.fetch_batch(:user_timeline, 
      arguments: [twitter_opts], &blk) 
  end


  # return an instantiated client
  def initialize_client(cred)
    Twitter::Client.new(cred)
  end

  # map loaded_creds into an array
  def parse_credentials(loaded_creds)
    app_hash = loaded_creds.dup.keep_if{|k,v| ['consumer_key', 'consumer_secret'].include?(k)}

    loaded_creds['tokens'].map{ |token|  token.merge(app_hash) }
  end

  # return something of your choice
  def load_credentials
    JSON.parse open( File.expand_path('../twitter_creds.json', __FILE__) )
  end


  def manager
    @manager ||= Manager.new
    @manager.init_and_authorize_clients([])
  end

end
