require 'spec_helper'
require 'webmock/rspec'
require 'stringio'
require 'tempfile'
require 'twitter'


$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'examples'))
require 'twitter_wrangler'




### helpers for Twitter testing


def a_delete(path)
  a_request(:delete, Twitter::REST::Client::ENDPOINT + path)
end

def a_get(path)
  a_request(:get, Twitter::REST::Client::ENDPOINT + path)
end

def a_post(path)
  a_request(:post, Twitter::REST::Client::ENDPOINT + path)
end

def a_put(path)
  a_request(:put, Twitter::REST::Client::ENDPOINT + path)
end

def stub_delete(path)
  stub_request(:delete, Twitter::REST::Client::ENDPOINT + path)
end

def stub_get(path)
  stub_request(:get, Twitter::REST::Client::ENDPOINT + path)
end

def stub_post(path)
  stub_request(:post, Twitter::REST::Client::ENDPOINT + path)
end

def stub_put(path)
  stub_request(:put, Twitter::REST::Client::ENDPOINT + path)
end