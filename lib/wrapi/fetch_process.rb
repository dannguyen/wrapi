require 'hashie'
require 'pry'
require 'awesome_print'
require_relative 'error_collector'
require_relative 'fetched_response'

module Wrapi
  class FetchProcess

    include Wrapi::ErrorCollector

    attr_reader :arguments, :process_name
    attr_reader :latest_response, :iteration_count


    def initialize(client_instance, process_name, opts={})
      set_client(client_instance)
      @process_name = process_name
      @iteration_count = 0
      @options = Hashie::Mash.new(opts)
      @latest_response = nil

      # Passing in the arguments from Fetcher's method   
     
      @arguments = @options[:arguments] || []
      raise ArgumentError, ":arguments needs to be an array, not a #{@arguments.class}" unless @arguments.is_a?(Array)

      @logger = @options[:logger]
      raise ArgumentError, ":logger must be an IO or nil, not #{@logger.class}" unless @logger.nil? || @logger.respond_to?(:puts)

      # define instance methods using passed-in procs
      # TODO: Refactor
      _while_condition = @options[:while_condition] || ->(foo_process, args){ foo_process.iteration_count < 1 }
      raise ArgumentError, ":while_condition needs to respond to :call" unless _while_condition.respond_to?(:call)
      define_singleton_method_by_proc(:while_condition, _while_condition )

      _response_callback = @options[:response_callback] || ->(foo_process, args){  }
      raise ArgumentError, ":response_callback needs to be a Proc with arity == 2" unless _response_callback.respond_to?(:call) && _response_callback.arity == 2 
      define_singleton_method_by_proc(:response_callback, _response_callback )
    

      set_operation( ->(){
           @managed_client.send_fetch_call( process_name, *@arguments )
        }
      )

    end

    # Public: convenient alias for @managed_client
    def client
      @managed_client
    end


    def serialize
      Hashie::Mash.new(
        process_name: @process_name,
        iteration_count: @iteration_count, 
        arguments: @arguments
      )
    end


    # Public: Allows the calling fetcher to replace the client
    def set_client(a_client_instance)
      raise ArgumentError, "first argument needs to be a ManagedClient, not a #{a_client_instance.class}" unless a_client_instance.is_a?(ManagedClient)
      @managed_client = a_client_instance
    end

    # runs @managed_client.perform
    # this should probably be false
    def execute!(&blk) 
      transcribe
      
      begin 
        a_response = perform_operation

      rescue StandardError => err        
        set_error(err)

        err.wrapi_data = self.serialize        
        response_object = FetchedResponse.error(err)
      else
        # success!
        response_object = FetchedResponse.success(a_response)
      end  

      @latest_response = response_object
      yield @latest_response

      return nil
    end

    def execute(&blk)
      if while_condition?
        execute!(&blk)
      else
        raise ExecutingWhileFalseError, "The while_condition evaluates to false"
      end
    end


    # allows Fetcher to manipulate the fetch_process, such as resetting arguments, etc.
    # and to set a new client
    #
    # Yields: :fetch_process
    #
    # at the end, the error is cleared
    def fix_error(&blk)
      error_handling_result = blk.call( self )
      
      ## force user to return true/false here
      case error_handling_result        
      when true
        clear_error!
      when false
        # do nothing
      else
        raise ImproperErrorHandling, "Error handling method must return true/false, not a #{error_handling_result.class}"
      end

      return error_handling_result
    end


    # Public: A method invoked by the fetcher, typically when the response is a success
    # The @iteration_count is incremented and stores the @latest_response
    # ...careful, proceed! is exposed wherever the fetch_process is yielded.
    def proceed!
      increment_loop_state!
      perform_response_callback
    end

    def transcribe(str=nil)
      return if @logger.nil?

      if str
        @logger.send :ap, nil
      else
        log_hsh = {process_name: @process_name, arguments: @arguments, timestamp: Time.now}
        @logger.send :ap, log_hsh, {sort_keys: false, limit: 20}
      end
    end


    def self.batch(client_instance, process_name, opts) 
      BatchFetchProcess.new(client_instance, process_name, opts)
    end


    def self.single(client_instance, process_name, opts)
      SingularFetchProcess.new(client_instance, process_name, opts)
    end




#############################################################
### methods used to test state of the FetchProcess

    def latest_body
      @latest_response.body if latest_response?
    end

    def latest_body?
      !latest_body.nil?
    end

    def latest_response?
      !latest_response.nil?
    end

    def latest_response_successful?
      return false unless latest_response?
      @latest_response.success?
    end

    def has_not_run?
      !has_run?
    end

    def has_run?
      @iteration_count > 0
    end

    # both the while_condition is true and TODO: errors have been resolved
    def ready_to_execute?
      (while_condition? == true) && !(unfixed_error?)
    end

    def while_condition?
      send(:while_condition, self, @arguments)
    end
    

    # used to initialize the operation to run on each iteration 
    # and in rare cases when it's necessary to change the operation
    #  after the initial run (koala.get_connections)

    # TK do a test
    def set_operation(foo_lambda)
      @_current_op = foo_lambda
    end

    # In the rare situation when we have methods that aren't called on
    # a client
    # for example, Koala:
    # response = @koala_client.get_connections('person')
    # response.next_page # to get to the next thing
    #
    # we still want to associate it with the current client
    # which will log the call
    # so wrap it up in a :generic_operation
    def set_generic_operation(foo_lambda)
      wrapped_foo = ->(){
           @managed_client.send_fetch_call( :generic_operation, foo_lambda)
        }
      set_operation(wrapped_foo)
    end

    private

    # Internal: Perform the specified client operation
    def perform_operation
      @_current_op.call 
    end

    # Internal: A poorly named method that obfuscates that this is the Proc passed in to 
    # work with the process and modify the arguments after each successful call
    def perform_response_callback
      response_callback(self, @arguments)
    end

    # Internal: A convenience method for turning the :while_condition proc to a singleton instance method
    def define_singleton_method_by_proc(foo_name, block)
      metaclass = class << self; self; end
      metaclass.send(:define_method, foo_name, block)
    end

    # Internal: to be deprecated soon, but called during #proceed!
    def increment_loop_state!
      @iteration_count += 1
    end
  end


  class SingularFetchProcess < FetchProcess
  end

  class BatchFetchProcess < FetchProcess 
    def initialize(client_instance, process_name, opts)
      super(client_instance, process_name, opts)

      raise ArgumentError, "Batch operations expect a while condition" unless @options[:while_condition]      
    end
  end



end