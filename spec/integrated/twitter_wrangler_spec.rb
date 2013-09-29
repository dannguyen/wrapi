require 'integration_helper'


describe TwitterWrangler do

  it 'should inherit Wrangler' do 
    expect(TwitterWrangler::const_defined?("Wrangler"))
  end
end


describe Twitter::Error do

  before do
    @client = Twitter::REST::Client.new(:consumer_key => "CK", :consumer_secret => "CS", :access_token => "AT", :access_token_secret => "AS")
  end


  for status, exception in Twitter::Error.errors
    for body in [nil, "error", "errors"]
      context "when HTTP status is #{status} and body is #{body.inspect}" do
        before do
          body_message = '{"' + body + '":"Client Error"}' unless body.nil?
          stub_get("/1.1/statuses/user_timeline.json").with(:query => {:screen_name => "sferik"}).to_return(:status => status, :body => body_message)
        end
        it "raises #{exception.name}" do
          expect{@client.user_timeline("sferik")}.to raise_error exception
        end
      end
    end
  end  



end