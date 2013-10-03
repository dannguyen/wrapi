module Wrapi
  module ErrorCollector
    extend ActiveSupport::Concern

    included do 
    end

    # returns a chrono-DESC sort of the errors array
    def errors_collection 
      @_errors_array.sort_by{|e| e.timestamp }.reverse
    end


    def errors_by_kind(err_klass)
      err_klass.nil? ? errors_collection : errors_collection.select{|e| e.kind_of?(err_klass)}
    end

    def most_recent_error(err_klass = nil)
      errors_by_kind(err_klass).first
    end

    def error_count(err_klass = nil)      
      arr =  errors_by_kind(err_klass)
      
      return arr.size
    end

    def unfixed_error?
      !@caught_error.nil?
    end


    private 

    def collect_error(err)
      @_errors_array ||= []
      @_errors_array  << err 
    end


    def log_error(err)
      err.extend Wrapi::ErrorTag
      err.timestamp = Time.now

      collect_error(err)
      err
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