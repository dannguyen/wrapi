class TwitterWrangler
  include Wrapi::Wrangler

  define_rate_errors(Twitter::RateLimit, Twitter::Something) do |manager, error|

    manager.remove_client(client)
    manager.find_new_client

    true
  end

  


  def fetch_batch_user_timeline(user_id, twitter_opts={}, &blk)
    manager.fetch_batch(:user_timeline, arguments: [twitter_opts], &blk) 
  end



  def initialize_client

  end

  def parse_credentials

  end

  def load_credentials

  end


  def manager
    @manager ||= Manager.new
    @manager.init_and_authorize_clients([])
  end

end
