require 'hashie'
require 'pry'

module Wrapi
  class FetchProcess


    attr_reader :mode, :arguments, :process_name
    attr_reader :latest_response, :iterations

    def initialize(client_instance, process_name, opts)
      @managed_client = client_instance
      @process_name = process_name
      @iterations = 0
      @options = Hashie::Mash.new(opts)

      @arguments = @options[:arguments] || []
      raise ArgumentError, ":arguments needs to be an array, not a #{@arguments.class}" unless @arguments.is_a?(Array)

      @transcript = @options[:transcript]
      raise ArgumentError, ":transcript must be an IO or nil, not #{@transcript.class}" unless @transcript.nil? || @transcript.respond_to?(:puts)

      # define instance methods using passed-in procs
      # TODO: Refactor
      _while_condition = @options[:while_condition] || ->(foo_process, args){ foo_process.iterations < 1 }
      raise ArgumentError, ":while_condition needs to respond to :call" unless _while_condition.respond_to?(:call)
      define_singleton_method_by_proc(:while_condition, _while_condition )

      _response_callback = @options[:response_callback] || ->(foo_process, args){  }
      raise ArgumentError, ":response_callback needs to be a Proc with arity == 2" unless _response_callback.respond_to?(:call) && _response_callback.arity == 2 
      define_singleton_method_by_proc(:response_callback, _response_callback )
    end

    # Public: convenient alias for @managed_client
    def client
      @managed_client
    end


    # Public: Allows the calling manager to replace the client
    def set_client(a_client_instance)
      @managed_client = a_client_instance
    end

    # runs @managed_client.perform
    def execute 
      transcribe("sending :#{@process_name} with :arguments => #{@arguments}") #todo: refactor

      begin 
        a_response = perform_client_operation
      rescue StandardError => err
        response_object = FetchedResponse.error(err)
      else
        response_object = FetchedResponse.success(a_response)
      end  

      @latest_response = response_object
      yield @latest_response

      return nil
    end

    def latest_body
      @latest_response.body 
    end

    def latest_response?
      !(latest_body.nil? && latest_body.empty?)
    end


    # Public: A method invoked by the manager, typically when the response is a success
    # The @iterations is incremented and stores the @latest_response
    # ...careful, proceed! is exposed wherever the fetch_process is yielded.
    def proceed!
      increment_loop_state!
      perform_response_callback
    end


    def while_condition?
      send(:while_condition, self, @arguments)
    end
    

    def transcribe(str)
      return if @transcript.nil?
      @transcript.puts str
    end


    def self.batch(client_instance, process_name, opts) 
      BatchFetchProcess.new(client_instance, process_name, opts)
    end


    def self.single(client_instance, process_name, opts)
      SingularFetchProcess.new(client_instance, process_name, opts)
    end


    private

    # Internal: Perform the specified client operation
    def perform_client_operation
      @managed_client.send( process_name, *arguments )
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
      @iterations += 1
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