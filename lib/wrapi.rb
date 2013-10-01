require 'hashie'
require 'active_support/core_ext/object'
require 'active_support/core_ext/class'
require 'active_support/core_ext/module'

module Wrapi
end

include Wrapi
require_relative 'wrapi/wrangler'

require_relative 'wrapi/error'