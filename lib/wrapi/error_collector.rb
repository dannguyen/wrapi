module Wrapi
  module ErrorCollector
    extend ActiveSupport::Concern

    included do 
    end


    def errors_collection 
      @_errors_collection ||= []

      @_errors_collection
    end

    def error_count(err_klass = nil)      
      arr = err_klass.nil? ? errors_collection : errors_collection.select{|e| e.kind_of?(err_klass)}
      
      return arr.size
    end

    def unfixed_error?
      !@caught_error.nil?
    end


    private 
    def log_error(err)
      err.extend Wrapi::ErrorTag    
      errors_collection << err
    end

    def clear_error!
      @caught_error = nil
    end

    # tags error
    def set_error(err)
      @caught_error = err
      log_error(@caught_error)

      @caught_error
    end


  end
end