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

    user_hash = arr.find{|h| h['username'].downcase == u_name}

    if u_id = user_hash['id']
      return fetch_profile_by_user_id(u_id)
    end
  end

  # username is a String
  # 
  # Returns: Hash
  def fetch_user_search(username)
    fetch_single(:user_search, arguments: [username])
  end


  # Requires a user_id as a string
  def fetch_batch_media(user_id, params={}, &blk)
    mash = prepare_fetcher_options
    mash[:arguments] = [user_id, params]
    mash[:while_condition] = ->(loop_state, args) do 
      loop_state.has_not_run? || !args[1][:max_id].nil?
    end

    mash[:response_callback] = ->(loop_state, args) do 
      args[1][:max_id] = loop_state.latest_body.pagination.next_max_id
    end

    fetch_batch :user_recent_media, mash, &blk
  end






  #################################
  #### Initialization stuff

  def initialize_client(cred)
    client = Instagram::Client.new
    client.client_id = cred['id']
    client.access_token = cred['access_token']

    client
  end

  def parse_credentials(loaded_creds)
    return loaded_creds # pass through
  end
  
  def load_credentials
    JSON.parse open( File.expand_path('../creds/instagram-creds.json', __FILE__) ){|f| f.read}
  end
end




=begin
  

load File.expand_path './examples/instagram_wrangler.rb'
wrangler = InstagramWrangler.init_clients

profile = wrangler.fetch_profile_with_username('danwinny')
user_id = profile['id']

arr = []
wrangler.fetch_batch_media(user_id) do |resp|
  arr += resp.body
end



client = wrangler.bare_clients.first
client.user_recent_media('181309234')


=end