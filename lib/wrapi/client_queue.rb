module Wrapi
  class ClientQueue

    def initialize(clientqueue=nil)            
      @_queue = []      
      add_clients( clientqueue ) unless clientqueue.nil?
    end

    def add_clients(arr)
      arr.each do |client|
        add_client(client)
      end
      
      nil
    end

    def add_client(ct)
      raise ArgumentError, "Only ManagedClients can be added, not #{ct.class}" unless ct.is_a?( ManagedClient ) 
      @_queue << ct 

      nil
    end


    def clients
      @_queue
    end

    def empty?
      @_queue.empty?
    end

    def size
      @_queue.count
    end

    def find_client
      @_queue.first
    end

    # returns true or false
    def remove_client(client)
      success = @_queue.delete client 

      return !!success 
    end


  end
end