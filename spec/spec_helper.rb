$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'timecop'
require 'wrapi'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}




#DatabaseCleaner.strategy = :truncation

RSpec.configure do |config|

  config.filter_run_excluding skip: true 
  config.run_all_when_everything_filtered = true
  config.filter_run :focus => true


   # Use color in STDOUT
  config.color_enabled = true

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate

  config.before(:each) do

  end
  config.after(:each) do

  end
end



