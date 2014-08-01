# encoding: UTF-8

require 'rubygems'
require 'twitter'
require './twitter_init'
require './variables'
require 'mongo'

include Mongo

source_tweets = []

class Tweet
  def self.create!(tweets)
    collection.insert(tweets)
  end

  private
    def self.establish_connection
     uri = $uri
     client = Mongo::MongoClient.from_uri($uri)
     db_name = uri[%r{/([^/\?]+)(\?|$)}, 1]
     db = client.db(db_name)
    end

    def self.get_latest_id
      cursor = collection.find().sort({id:-1}).limit(1).map { |h| h["id"] }.last
    end

    def self.db
      @db ||= establish_connection
    end

    def self.collection
      @collection ||= db.collection("tweets")
    end
end

def filtered_tweets(tweets)
    source_tweets = tweets.map {|t| {id: t.id, text: t.text} }
end

client = Twitter::REST::Client.new do |config|
  config.consumer_key = $consumer_key
  config.consumer_secret = $consumer_secret
  config.access_token = $access_token
  config.access_token_secret = $access_token_secret
end

#get latest id from mongo
max_id = Tweet.get_latest_id
puts "oldest already stored: #{max_id}"
user_tweets = client.user_timeline($source_account, :count => 200, :trim_user => true, :include_rts => false, :since_id => max_id)
puts "TWEETS: #{user_tweets.length}"
source_tweets += filtered_tweets(user_tweets)
  
puts "#{source_tweets.length} tweets found"

if source_tweets.length == 0
  raise "No tweets found from Twitter. Aborting."
end
  
source_tweets.each do |t|
  data = { "id" => t[:id], "text" => t[:text]}
  Tweet.create!(data)
end
