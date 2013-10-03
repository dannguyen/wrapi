require_relative '../lib/wrapi'
require 'koala'


class FacebookWrangler
  include Wrapi::Wrangler

  ############# singular
  def fetch_object
  end

  ############# batch
  def fetch_batch_comments_on_object
  end


  def fetch_batch_wall_posts
  end




  #################################
#### Initialization stuff

  def initialize_client(cred)
    Koala::Facebook::API.new(cred)
  end

  def parse_credentials(loaded_creds)
  end

  def load_credentials()
  end




end