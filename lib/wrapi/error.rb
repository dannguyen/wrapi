module Wrapi


  module ErrorTag
    attr_accessor :wrapi_data
    attr_accessor :timestamp

    def process_name
      wrapi_data.process_name
    end

  end
  

  class Error < StandardError; end

  class ProcessingError < Error; end
  class ImproperErrorHandling < Error; end
  class ExecutingWhileFalseError < Error; end 
end
