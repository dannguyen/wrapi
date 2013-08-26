module Wrapi
  class ClientPool

    def initialize(clientpool_array)            
      @_pool = clientpool_array
    end

    def add_clients(arr)
      array = arr.is_a?(Hash) ? [arr] : Array(arr)
      array.each do |client|
        @_pool << client 
      end
      
      nil
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


  end
end
