require 'delegate'

module Wrapi
  class ManagedClient < SimpleDelegator

    attr_reader :last_call_timestamp

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


    def before_call
      @last_call_timestamp = Time.now 
    end

    def method_missing(name, *args, &block)
      before_call
      @client.send name, *args, &block
    end

    def respond_to_missing?(name, include_private = false)
      @client.respond_to_missing?(name) or super
    end


  end
end