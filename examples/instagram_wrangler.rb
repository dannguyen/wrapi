require_relative '../lib/wrapi'
require 'instagram'


class InstagramWrangler
  include Wrapi::Wrangler

  ##### one off
  def fetch_profile_by_user_id(uid)
    fetch_single(:user, arguments: [uid])
  end


  # convenience method if all you got is a username
  def fetch_profile_with_username(username)
    u_name = username.downcase
    # do a search for :u_name
    arr = fetch_user_search(u_name)

    user_hash = arr.find{|h| h['username'].downcase == u_name}.first

    if u_id = hsh['id']
      return fetch_profile_by_user_id(u_id)
    end
  end

  # username is a String
  # 
  # Returns: Hash
  def fetch_user_search(username)
    fetch_single(:user_search, arguments: [uid])
  end


  # Requires a user_id as a string
  def fetch_batch_media(user_id, params={})
    mash = prepare_fetcher_opts
    mash[:arguments] = [user_id, params]
    mash[:while_condition] = ->(loop_state, args) do 
      loop_state.has_not_started? || args[0][:max_id].nil?
    end

    mash[:response_callback] = ->(loop_state, args) do 
      args[0][:max_id] = loop_state.latest_body.pagination.next_max_id
    end
  end






  #################################
  #### Initialization stuff

  def initialize_client(cred)
    Instagram::Client.new(cred)
  end

  def parse_credentials(loaded_creds)
    loaded_creds
  end
  
  def load_credentials
    JSON.parse open( File.expand_path('../creds/instagram-creds.json', __FILE__) ){|f| f.read}
  end



end