require 'active_support/core_ext'
require 'hashie'

module Wrapi
  module Wrangler
    extend ActiveSupport::Concern

    included do 
      class_attribute :list_of_handled_errors
      attr_reader :credentials
    end


    module ClassMethods
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



      def parse_credentials(*args)
        # Abstract
      end

      def load_credentials(*args)
        # Abstract
      end

      def initialize_client(credential_unit)
        
      end


      def credentialize
        @credentials = parse_credentials load_credentials
      end
    end

  end
end

require_relative 'client_pool'