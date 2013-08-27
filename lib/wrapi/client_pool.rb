module Wrapi
  class ClientPool

    def initialize(clientpool=nil)            
      @_pool = []      
      add_clients( clientpool ) unless clientpool.nil?
    end

    def add_clients(arr)
      arr.each do |client|
        add_client(client)
      end
      
      nil
    end

    def add_client(ct)
      raise ArgumentError, "Only ManagedClients can be added, not #{ct.class}" unless ct.is_a?( ManagedClient ) 
      @_pool << ct 

      nil
    end


    def clients
      @_pool
    end

    def empty?
      @_pool.empty?
    end

    def size
      @_pool.count
    end

    def find_client
      @_pool.first
    end

    # returns true or false
    def remove_client(client)
      success = @_pool.delete client 

      return !!success 
    end


  end
end
