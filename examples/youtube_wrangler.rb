require_relative '../lib/wrapi'
require 'google/api_client'


class YoutubeWrangler
  include Wrapi::Wrangler

  attr_reader :google_api
  MAX_RESULTS = 50
  DEFAULT_PARTS = %w(id snippet contentDetails status)

# Note all fetches end up invoking get_list, and there's no real batch calls



############# FETCHING CHANNEL IDs and USERNAMES

  def fetch_channel_by_id(id, opts={})
    ids = Array(id).join(',')
    options =   opts.dup.merge({ id: ids })

    get_list('channels', options)
  end

  def fetch_batch_channels_by_id(ids, opts={})
    # to do: each_slice of ids to be under max count
    ids.each_slice(MAX_RESULTS) do |sub_array|
      resp = fetch_channel_by_id(sub_array, opts)
      yield resp
    end
  end

  def fetch_channel_by_username(youtube_username, opts={})
    # to do: modularize this so that it yields each result
    youtube_usernames = Array(youtube_username)
    yid = []
   
    youtube_usernames.each do |username|
      yid << convert_username_to_id(username)
    end
    get_channel_by_id(yid, opts)
  end


  def fetch_batch_channels_by_usernames(youtube_username, opts={})
    # TK need to refactor for batches > 50
    fetch_channel_by_username(youtube_username, opts)
  end





################# FETCHING PLAYLISTS
  
  def fetch_batch_playlist_items(playlist_id, opts={})
    options = opts.dup.merge({ playlistId: playlist_id })

    get_list('playlist_items', options)
  end



  # Note: This may not be needed?
  # Removes the cumbersome playlist_item wrapper and just extracts the video_id
  def fetch_and_parse_video_ids_from_playlist_items(playlist_id, opts={})
    # convenience method
    # todo TK: get lists > 50
    playlist = fetch_playlist(playlist_id, opts)

    return playlist.map{|v| v.snippet.resourceId.videoId }
  end


################# fetching videos
  def fetch_video(v_id, opts={}) # from feed
    video_ids = Array(v_id).join(',')
    options = opts.dup.merge(id: video_ids)

    get_list('videos', options)
  end

  def fetch_batch_videos(v_ids, opts={})
    # TK todo 
    # involves pagination?

    fetch_video(v_ids, opts)
  end


####
  # get_list is a method to which all YoutubeWrangler methods direct to 
  # not sure the best way to integrate it with fetch

####


 # Helper methods

 # youtube_username: 
  # returns a string for user ID
  def convert_username_to_id(youtube_username)
    options = { forUsername: youtube_username, part: 'id' }
    result = get_list('channels', options)

    result["items"].first["id"]
  end


  # given a channel's id, get its upload playlist
  # channel_id: String, a channel's id
  #
  # Note, the playlist uploads id always seems to be the same as channel's id, 
  # except for the second character:
  # e.g. 
  # Delta.id:     UC0KHhAOmmHCBGea_V5GsEDg
  # Delta.up_id:  UU0KHhAOmmHCBGea_V5GsEDg
  #
  def fetch_playlist_id_of_channel_uploads(channel_id, opts={})
    results = fetch_channel_by_id(channel_id, opts)
    unless results['items'].empty?
      results['items'].first['contentDetails']['relatedPlaylists']['uploads']
    end
  end




  private


 
  def get_list(method_name, _params = {}, process_type=:single)
    fetcher_opts = prepare_fetcher_options

    params = _params.dup
    params[:part] ||= DEFAULT_PARTS.join(',')
    params[:maxResults] ||= MAX_RESULTS

    # Note: We use the form of calling googleclient with two arguments: method, hash
    # else there is a obscure bug with indifferent hashes

    fetcher_opts[:arguments] = [@google_api.send(method_name).list, params]

    resp = fetch_single :execute!, fetcher_opts
    
    convert_response_data(resp)
  end

  def convert_response_data(resp)
    return Hashie::Mash.new(resp.data.to_hash)
  end


  protected

  GOOGLE_API_SERVICE_NAME = 'youtube'
  GOOGLE_API_SERVICE_VERSION = 'v3'
  #################################
#### Initialization stuff

  def initialize_client(cred)

    # (:key => opts[:DEVELOPER_KEY],
    # :authorization => nil,
    # :application_name => 'SkiftIQ',
    #  :application_version => '1.0')

    client = Google::APIClient.new(cred)
    # WARNING, TK: @google_api is a attr_reader for Wrangler, meaning that Wrangler can only
    # have one Google API at a time. Not a real concern if this is just a Youtube Client though
    # set the discovered api globally
    # this could be buggy with more than one client
    @google_api = client.discovered_api(GOOGLE_API_SERVICE_NAME, GOOGLE_API_SERVICE_VERSION)

    return client
  end


  # loaded_creds is an array
  def parse_credentials(loaded_creds)
    loaded_creds
  end

  
  def load_credentials()
    JSON.parse open( File.expand_path('../creds/youtube-creds.json', __FILE__) ){|f| f.read}
  end
end


=begin
  

load File.expand_path './examples/youtube_wrangler.rb'
y = YoutubeWrangler.init_clients

arr_of_ids = []  << y.convert_username_to_id( 'DeltaAirLines') << y.convert_username_to_id( 'Jetblue')

channel_resp = y.fetch_channel_by_id(arr_of_ids)

# resp has the data wrapped up, need to extract items
items = channel_resp.items

channel_id = items.first.id
upload_list_id = y.fetch_playlist_id_of_channel_uploads(channel_id)


playlist = y.fetch_batch_playlist_items(upload_list_id)
playlist_items = playlist.items
video_id = videos.first.snippet.resourceId.videoId


# convenience method
video_ids = fetch_and_parse_video_ids_from_playlist_items(upload_list_id)
video_id = video_ids.first

y.fetch_video(video_id)





=end  
