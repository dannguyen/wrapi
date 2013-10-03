require_relative '../lib/wrapi'
require 'instagram'


class InstagramWrangler
  include Wrapi::Wrangler

  ##### one off
  def fetch_profile_by_user_id

  end


  def fetch_profile_with_username(username)

  end


  def fetch_batch_media

  end




  #################################
  #### Initialization stuff

  def initialize_client(cred)
    Instagram::Client.new(cred)
  end

  def parse_credentials(loaded_creds)
  end

  def load_credentials()
  end




end