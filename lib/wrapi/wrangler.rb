require 'hashie'

module Wrapi
  module Wrangler
    extend ActiveSupport::Concern

    included do 
      class_attribute :list_of_handled_errors
      attr_reader :credentials



      # hello bi-directional knowledge!
      # TODO: Wrangler should be concerned only with a pool of Fetchers, not clients
      # for now, a Wrangler is responsible for one fetcher
      delegate :add_clients,
                        :has_clients?, :bare_clients, :clients, 
                        :fetch_single, :fetch_batch, :fetch,
                        :register_error_handler, :get_error_handler,
                          :to => :@fetcher
    end # end included


    module ClassMethods
      def init_clients(*args)
        w = self.new 
        w.load_credentials_and_initialize_clients(*args)

        return w
      end
    end
    

    def initialize
      @fetcher = Fetcher.new
      register_error_handling
    end

    # Public: Wraps the private individual error handling routines
    # abstract method
    def register_error_handling
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
      return []
    end

    def load_credentials(*args)
      # Abstract 
    end

    def initialize_client(credential_unit)
      credential_unit
    end

  end
end

require_relative 'fetcher' 
