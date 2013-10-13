require_relative '../lib/wrapi'
require 'koala'


class FacebookWrangler
  include Wrapi::Wrangler

  SENSIBLE_FEED_LIMIT = 100

  ############# singular
  def fetch_object(object_id)
    fetch_single :get_object, arguments: [object_id]
  end


  # returns an integer
  # Example json: https://graph.facebook.com/125909647492772_502974003098530/comments?summary=1
  def fetch_comments_count_on_object(object_id)
    fetch_summary(object_id, :comments)
  end

  def fetch_likes_count_on_object(object_id)
    fetch_summary(object_id, :likes)
  end


  ############# batch
  def fetch_batch_comments_on_object(object_id, f_opts={}, &blk)
    fetch_batch_connections(object_id, :comments, f_opts, &blk)
  end


  def fetch_batch_feed(page_id, f_opts={}, &blk)
    fetch_batch_connections(page_id, :feed, f_opts, &blk)
  end

  def fetch_batch_posts(page_id, f_opts={}, &blk)
    fetch_batch_connections(page_id, :posts, f_opts, &blk)
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



  private
    # a convenience method for doing all type of koala#next_page calls
  def koala_next_page_proc 
    ->(loop_state, args) do
        koala_resp = loop_state.latest_body 
        loop_state.set_generic_operation ->(){
          # use next_page to paginate through
          koala_resp = koala_resp.next_page
        }
    end   
  end


  # helper method
  def fetch_summary(object_id, foo_name)

    if foo_name !~ /likes|comments/
      raise ArgumentError, "Second arg must be `likes` or `comments`, not #{foo_name}"
    end

    params = prepare_fetcher_options
    # graph.facebook.com/99999/:foo_name?summary=1&limit=0
    params[:arguments] = [object_id, foo_name, {'summary' => 1, 'limit' => 0} ]
    resp = fetch_single :get_connections, params
    # convert to raw_response
    rr = resp.raw_response

    if s = rr['summary'] 
      return s['total_count']
    end
  end

  def fetch_batch_connections(object_id, foo_name, f_opts, &blk)
    facebook_opts = Hashie::Mash.new(f_opts)
    facebook_opts[:limit] ||= SENSIBLE_FEED_LIMIT

    params = prepare_fetcher_options
    params[:arguments] = [object_id, foo_name, facebook_opts]
    params[:while_condition] = ->(loop_state, args) do 
      # koala.response.next_page returns nil if at the end of pagination
     ( loop_state.has_not_run? || loop_state.latest_body?)
    end

    params[:response_callback] = koala_next_page_proc

    fetch_batch :get_connections, params, &blk
  end
end



=begin
load File.expand_path './examples/facebook_wrangler.rb'
wrangler = FacebookWrangler.init_clients

screen_name = 'theenjoycentre'
profile = wrangler.fetch_object(screen_name)


feed = [] 
count = 0
wrangler.fetch_batch_feed('Delta') do |f|  
  fbody = f.body  
  feed += fbody
  count += 1
  puts count
  sleep 2.4
end


posts = [] 
count = 0
wrangler.fetch_batch_posts('Delta') do |f|  
  fbody = f.body  
  posts += fbody
  count += 1
  puts count
  sleep 2.4
end


object_id = '666240360061816'
comments = []
wrangler.fetch_batch_comments_on_object(object_id) do |resp|
  comments << resp.body
  sleep 1
  puts "Size is #{comments.size}"
end


comments_count = wrangler.fetch_comments_count_on_object(object_id)
likes_count = wrangler.fetch_likes_count_on_object(object_id)

=end