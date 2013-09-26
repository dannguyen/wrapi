require 'spec_helper'

class CallingWrangler 
  include Wrapi::Wrangler
end

describe 'Wrapi::Wrangler' do 

  context 'convenience calls' do 
    it 'should use fetcher to handle batch calls'
    it 'should use fetcher to handle singular calls'
  end

end