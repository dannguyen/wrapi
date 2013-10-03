require_relative '../lib/wrapi'
require 'google/api_client'


class YoutubeWrangler
  include Wrapi::Wrangler

  attr_reader :google_api

  ############# singular
  def fetch_channel
  end


  ############# batch
  def fetch_videos # from feed
  end


####
  # get_list is a method to which all YoutubeWrangler methods direct to 
  # not sure the best way to integrate it with fetch

####

  private

  MAX_RESULTS = 50
  DEFAULT_PARTS = %w(id snippet contentDetails)

  def convert_username_to_id(youtube_username)
    options = { forUsername: youtube_username, part: 'id' }

    result = get_list('channels', options)
    result["items"].first["id"]
  end


  def get_channel_id_of_upload_playlist


  end

  def get_list(method_name, o = {})
    opts = Hashie::Mash.new(o)
    opts[:part] ||= DEFAULT_PARTS.join(', ')
    opts[:maxResults] ||= MAX_RESULTS


    resp = fetch_singular :execute!, 
      arguments: { 
        api_method: @google_api.send(method_name).list
        parameters: opts
      }

    convert_response_data(resp)
  end

  def convert_response_data(resp)
    return Hashie::Mash.new(resp.data.to_hash)
  end


  protected

  #################################
#### Initialization stuff

  def initialize_client(cred)
    client = Google::APIClient.new(cred)

    # (:key => opts[:DEVELOPER_KEY],
    # :authorization => nil,
    # :application_name => 'SkiftIQ',
    #  :application_version => '1.0')

    # set the discovered api globally
    # this could be buggy with more than one client
    @google_api = @client.discovered_api(cred[:YOUTUBE_API_SERVICE_NAME], cred[:YOUTUBE_API_VERSION])
  end



  def parse_credentials(loaded_creds)
  end

  def load_credentials()
  end







end