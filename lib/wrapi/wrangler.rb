require 'active_support/core_ext'
require 'hashie'

module Wrapi
  module Wrangler
    extend ActiveSupport::Concern

    included do 
      class_attribute :list_of_handled_errors
      attr_reader :credentials

      extend Forwardable

      # hello bi-directional knowledge!
      def_delegators :@manager, :has_clients?, :bare_clients, :clients
    end


    def initialize
      @manager = Manager.new
    end

    module ClassMethods

      def init_clients(*args)
        w = self.new 
        w.load_credentials_and_initialize_clients(*args)

        return w
      end


      def handle_error(err_klass, &blk)
        unless err_klass < Exception
          raise ArgumentError, "Please pass in an Exception/Error class, not a #{err_klass}"
        end        

        unless block_given? && blk.arity == 1
          raise LocalJumpError, 'Need to pass a block in with 1 argument'
        end

        handled_errors[err_klass] = Hashie::Mash.new(handling: blk)
      end


      def handle_rate_limited_error

      end


      def handled_errors
        self.list_of_handled_errors ||= Hashie::Mash.new
      end
    end


    # cred_thingies is what 
    # the user-specified load_credentials wants 
    
    def load_credentials_and_initialize_clients(*cred_thingies)
      @credentials = parse_credentials load_credentials(*cred_thingies)      

      @credentials.each do |cred|
        client = initialize_client(cred)
        @manager.add_clients(client)
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
      
    end

  end
end

require_relative 'manager' 
