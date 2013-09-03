require 'hashie'
require 'pry'

module Wrapi
  class FetchProcess

    attr_reader :mode, :managed_client, :arguments, :process_name
    attr_reader :latest_response, :loop_state

    def initialize(client_instance, process_name, opts)
      @managed_client = client_instance
      @process_name = process_name
      @options = Hashie::Mash.new(opts)

      @loop_state = Hashie::Mash.new({iterations: 0})

      @arguments = @options[:arguments] || []
      raise ArgumentError, ":arguments needs to be an array, not a #{@arguments.class}" unless @arguments.is_a?(Array)

      @transcript = @options[:transcript]
      raise ArgumentError, ":transcript must be an IO or nil, not #{@transcript.class}" unless @transcript.nil? || @transcript.respond_to?(:puts)

      # define instance methods using passed-in procs
      # TODO: Refactor
      _while_condition = @options[:while_condition] || ->(loop_state, args){ loop_state.iterations < 1 }
      raise ArgumentError, ":while_condition needs to respond to :call" unless _while_condition.respond_to?(:call)
      define_singleton_method_by_proc(:while_condition, _while_condition )

      _response_callback = opts[:response_callback] || ->(loop_state, args){  }
      raise ArgumentError, ":response_callback needs to be a Proc with arity == 2" unless _response_callback.respond_to?(:call) && _response_callback.arity == 2 
      define_singleton_method_by_proc(:response_callback, _response_callback )
    end

    def client
      @managed_client
    end

    # runs @managed_client.perform
    def execute 
      begin 
        a_response = perform_client_operation
      rescue StandardError => err
        response_object = FetchedResponse.error(err)
      else
        response_object = FetchedResponse.success(a_response)
      end  

      @latest_response = response_object

      yield @latest_response

      ### maintenence
      transcribe("sending :#{@process_name} with :arguments => #{@arguments}") #todo: refactor
      increment_loop_state!
      perform_response_callback

      return nil
    end



    def while_condition?
      send(:while_condition, @loop_state, @arguments)
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

    def perform_client_operation
      @managed_client.send( process_name, *arguments )
    end

    def perform_response_callback
      response_callback(@loop_state, @arguments)
    end


    def define_singleton_method_by_proc(foo_name, block)
      metaclass = class << self; self; end
      metaclass.send(:define_method, foo_name, block)
    end

    # code smell TODO: dependency on @latest_response
    def increment_loop_state!
      @loop_state.iterations += 1
      @loop_state.latest_response = @latest_response
      @loop_state.latest_body = @latest_response.body 
      @loop_state[:latest_response?] = !(@loop_state.latest_body.nil? && @loop_state.latest_body.empty?)
    end


  end


  class SingularFetchProcess < FetchProcess
  end

  class BatchFetchProcess < FetchProcess 
    def initialize(client_instance, process_name, opts)
      super(client_instance, opts)

      raise ArgumentError, "Batch operations expect a while condition" unless @options[:while_condition]      
    end
  end



end