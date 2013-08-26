require 'delegate'

module Wrapi
  class ManagedClient < SimpleDelegator


    def initialize(client)
      @client = client 
      super(@client)
    end


    def bare_client
      @client 
    end

    def is_managed?
      true # just to keep this from being delegated to @client
    end

  end
end