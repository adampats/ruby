# twitter-searchr.rb
# -Search tweets for a given user for a string and return matching tweets.
# -Go to https://apps.twitter.com to generate an app token.
# -TODO: Add tweet.url to the response JSON
# -TODO: Get more tweets than the user_timeline limit of 200
# -TODO: Fix tweet text truncation
# -TODO: Add command line paratmers
#
# Usage:
#  twitter-searchr.rb

require 'yaml'
require 'twitter'
require 'json'
require 'pry-byebug'

### Parameters
keyfile = 'twitter-account.yml'
user = "@adampats"
find_text = "cloud"

### Methods
def get_user_id(user_query)
  users = @client.user_search(user_query, count: 1)[0]
end

def find_tweets(user_id,tweet_query)
  tweets = @client.user_timeline(user_id, count: 3200)
  matches = tweets.select{ |k| k.text.include?(tweet_query) }
  r_matches = matches.map{ |h| h.to_hash.select{ |k,_| %i[created_at text].include? k }}
end

### Script
puts "start"
keys = YAML.load(File.read(keyfile))
@client = Twitter::REST::Client.new do |config|
  config.consumer_key        = keys['consumer_key']
  config.consumer_secret     = keys['consumer_secret']
  config.access_token        = keys['access_token']
  config.access_token_secret = keys['access_secret']
end

user_id = get_user_id(user)
puts "Found @#{user_id.screen_name}!"

tweet_matches = find_tweets(user_id,find_text)
puts "Tweet matches:"
puts JSON.pretty_generate(tweet_matches)
