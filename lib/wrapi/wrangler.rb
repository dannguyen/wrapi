require 'hashie'
require 'logger'


module Wrapi
  module Wrangler
    extend ActiveSupport::Concern

    included do 
      class_attribute :list_of_handled_errors
      attr_reader :credentials
      attr_accessor :logger


      # hello bi-directional knowledge!
      # TODO: Wrangler should be concerned only with a pool of Fetchers, not clients
      # for now, a Wrangler is responsible for one fetcher
      delegate :add_clients,
                        :has_clients?, :bare_clients, :clients, 
                        :fetch_single, :fetch_batch, :fetch_simple, :fetch,
                        :register_error_handler, :get_error_handler, 
                        :shuffle_clients_before_fetch?, # ad-hoc 
                          :to => :@fetcher

    end # end included


    module ClassMethods
      def init_clients(*args)
        w = self.new(*args) 
        w.load_credentials_and_initialize_clients(*args)

        return w
      end

      def init!(*args)
        init_clients(*args)
      end
    end
    

    # this is where shuffling gets passed in
    def initialize(*args)
      if args[0].is_a?(Hash)
        @fetcher = Fetcher.new args[0]
      else
        @fetcher = Fetcher.new
      end
      @logger = nil
      register_error_handlers
    end


    # Public: Wraps the private individual error handling routines
    # abstract method
    def register_error_handlers
      # define in mixin
    end




    # cred_thingies is what 
    # the user-specified load_credentials wants 
    
    def load_credentials_and_initialize_clients(*cred_thingies)
      @credentials = parse_credentials load_credentials(*cred_thingies)      

      @credentials.each do |cred|
        client = initialize_client(cred)
        @fetcher.add_clients(client)
      end

      true 
    end

    def parse_credentials(*args)
      # Abstract
      "WARNING: Called the abstract implementation"
      []
    end

    def load_credentials(*args)
      # Abstract 
      "WARNING: Called the abstract implementation"
    end

    def initialize_client(credential_unit)
      credential_unit
    end


    private

    def prepare_fetcher_options
      m = Hashie::Mash.new 
      m[:logger]  = @logger

      return m 
    end

  end
end



require_relative 'fetcher' 

