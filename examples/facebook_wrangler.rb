require_relative '../lib/wrapi'
require 'koala'


class FacebookWrangler
  include Wrapi::Wrangler

  SENSIBLE_FEED_LIMIT = 100

  ############# singular
  def fetch_object(object_id)
    fetch_single :get_object, arguments: [object_id]
  end

  ############# batch
  def fetch_batch_comments_on_object
  end


  def fetch_batch_feed(page_id, f_opts={})
    facebook_opts = Hashie::Mash.new(f_opts)
    facebook_opts[:limit] ||= SENSIBLE_FEED_LIMIT

    params = prepare_fetcher_options
    params[:arguments] = [:feed, facebook_opts]
    params[:while_condition] = ->(loop_state, args) do 
      loop_state.has_not_run? || loop_state.latest_body?
    end

    params[:response_callback] = ->(loop_state, args) do 
      set_operation = ->(){
        loop_state.latest_body.next_page        
      }
    end


    fetch_batch :get_connections, params
  end




  #################################
#### Initialization stuff

  def initialize_client(cred)
    token = cred['token']
    Koala::Facebook::API.new(token)
  end

  def parse_credentials(loaded_creds)
    return loaded_creds # pass through
  end
  
  def load_credentials
    JSON.parse open( File.expand_path('../creds/facebook-creds.json', __FILE__) ){|f| f.read}
  end
end



=begin
load File.expand_path './examples/facebook_wrangler.rb'
wrangler = FacebookWrangler.init_clients

profile = wrangler.fetch_object('delta')


=end