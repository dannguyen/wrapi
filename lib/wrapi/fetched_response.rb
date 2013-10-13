require 'hashie'
module Wrapi
  class FetchedResponse
    
    attr_reader :body, :error, :status 

    ## factory methods
    def self.success(body=nil)
      new :success, body: body
    end

    def self.error(err=nil, body=nil)
      new :error, :error => err, :body => body
    end

    def initialize(status_type, opts={})
       mash_opts = opts.dup
       @status = status_type        
       @body = mash_opts[:body]
       @error = mash_opts[:error]
    end

    # note: we use :dup instead of Hashie::Mash.new because 
    # Mash will kill the overloaded array that Instagram returns
    # 
    # arr = instagram_wrangler.fetch
    # arr.respond_to?(:pagination) #=> true 
    # mash = Hashie::Mash{body: arr}
    #
    # mash.body.respond_to?(:pagination) #=> false






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

    # remove the body
    def trim_body!
      @body = []
    end


    def method_missing(name, *args, &block)
      if body.respond_to?(name)
        body.send(name, *args, &block)
      else
        super
      end
    end


  end
end