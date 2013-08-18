require 'hashie'
module Wrapi
  class FetchedResponse
    
    attr_reader :body, :error 

    ## factory methods
    def self.success(body=nil)
      new :success, body: body
    end

    def self.error(err=nil, body=nil)
      new :error, :error => err, :body => body
    end

    def initialize(status_type, opts={})
       @status = status_type
       mash_opts = Hashie::Mash.new(opts)
       @body = mash_opts.body
       @error = mash_opts.error
    end

    def success?
      @status == :success
    end

    def error?
      @status == :error
    end

    def on_error(&block)
      yield @error, @body if error?
    end

    def on_success(&block)
      yield @body if success?
    end

  end
end