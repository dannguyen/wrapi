module Wrapi


  module ErrorTag
    attr_accessor :wrapi_data
    attr_accessor :timestamp
  end
  

  class Error < StandardError; end

  class ProcessingError < Error; end
  class ImproperErrorHandling < Error; end
  class ExecutingWhileFalseError < Error; end 
end
