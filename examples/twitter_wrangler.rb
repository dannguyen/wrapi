require 'json'
require 'twitter'

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
    manager.fetch_batch(:user_timeline, arguments: [twitter_opts], &blk) 
  end



  def initialize_client

  end

  def parse_credentials(loaded_creds)
    loaded_creds['tokens'].map do |token|
      token.merge({})
    end
  end

  def load_credentials
    JSON.parse open( File.expand_path('../twitter_creds.yml', __FILE__) )
  end


  def manager
    @manager ||= Manager.new
    @manager.init_and_authorize_clients([])
  end

end
