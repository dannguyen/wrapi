require 'integration_helper'


describe TwitterWrangler do

  it 'should inherit Wrangler' do 
    expect(TwitterWrangler::const_defined?("Wrangler"))
  end
end


describe "Rate limiting" do

  before do
    @client = Twitter::REST::Client.new(:consumer_key => "CK", :consumer_secret => "CS", :access_token => "AT", :access_token_secret => "AS")
    @reset_time = (Time.now + 1.hour)

    stub_get("/1.1/statuses/user_timeline.json").with( 
      :query => {:screen_name => "ev"}).
      to_return(
        :status => 429, 
        :body => ({content: "Rate limit exceeded"}.to_json),
        :headers => {:content_type => "application/json; charset=utf-8", 
          "x-rate-limit-reset" => @reset_time.to_i.to_s
        }
      )
  end


  it 'should raise a TimeLimit sanity test' do
    begin 
     @client.user_timeline('ev')
    rescue => err 
      expect(err).to be_a Twitter::Error::TooManyRequests
      rate_limit = err.rate_limit
      expect(rate_limit.reset_at).to be_within(2.seconds).of @reset_time

      Timecop.travel(@reset_time)
      expect(rate_limit.reset_in).to eq 0
    end
  end


  context 'TwitterWrangler' do 
    before(:each) do 
      @wrangler = TwitterWrangler.new
      @wrangler.add_clients(@client)
      @query_string = "https://api.twitter.com/1.1/statuses/user_timeline.json?count=200&include_rts=true&max_id=4611686018427387903&screen_name=ev&since_id=1&trim_user=true"

      @error_response = {
        :status => 429, :body => ({content: "Rate limit exceeded"}.to_json),
        :headers => {:content_type => "application/json; charset=utf-8", 
          "x-rate-limit-reset" => @reset_time.to_i.to_s }
      }

      @success_response = {
        :status => 429, :body => ({content: "Rate limit exceeded"}.to_json),
        :headers => {:content_type => "application/json; charset=utf-8", 
          "x-rate-limit-reset" => @reset_time.to_i.to_s }        
      }

      stub_request(:get, @query_string).to_return(@error_response)
    end


    context 'rate limit error response' do 
      it 'should raise a Twitter::Error::TooManyRequests error' do 
        expect{ @wrangler.fetch_batch_user_timeline('ev') }.to raise_error Twitter::Error::TooManyRequests
      end
    end
  end


end




=begin
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
=end