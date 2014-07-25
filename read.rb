# encoding: UTF-8

require 'rubygems'
require 'twitter'
require './twitter_init'
require './variables'
require 'mongo'
require 'htmlentities'

include Mongo

source_tweets = []

class Tweet
  def self.create!(tweets)
    collection.insert(tweets)
  end

  def self.fetch
# get all rows {}. dont get _id field .get tweet field. map to ruby hash from mongo hash. map the tweet key values
    ##cursor = collection.find({},{:fields => {"_id" => 0, "text" => 1}}).limit(25).map { |h| h["text"] }
    cursor = collection.find({},{:fields => {"_id" => 0, "id" => 1, "text" => 1}}).limit(25).map { |h| h }
  end

  private
    def self.establish_connection
     uri = $uri
     client = Mongo::MongoClient.from_uri($uri)
     db_name = uri[%r{/([^/\?]+)(\?|$)}, 1]
     db = client.db(db_name)
    end

    def self.db
      @db ||= establish_connection
    end

    def self.collection
      @collection ||= db.collection("tweets")
    end
end

def filtered_tweets(tweets)
  html_decoder = HTMLEntities.new
  include_urls = $include_urls || params["include_urls"]
  include_replies = $include_replies || params["include_replies"]
  source_tweets = tweets.map {|t| html_decoder.decode(t).gsub(/\b(RT|MT) .+/, '') }

  if !include_urls
    source_tweets = source_tweets.reject {|t| t =~ /(https?:\/\/)/ }
  end

  if !include_replies
    source_tweets = source_tweets.reject {|t| t =~ /^@/ }
  end

  source_tweets.each do |t| 
#    t.gsub!(/(\#|(h\/t)|(http))\S+/, '')
    t.gsub!(/(@[\d\w_]+\s?)+/, '')
    t.gsub!(/[”“]/, '"')
    t.gsub!(/[‘’]/, "'")
    t.strip!
  end

  source_tweets
end

  begin
    user_tweets = Tweet.fetch
    source_tweets += filtered_tweets(user_tweets)
  end
  
  puts "#{source_tweets.length} tweets found"

  if source_tweets.length == 0
    raise "Error fetching tweets from Twitter. Aborting."
  end
  
source_tweets.each do |t|
  puts "#{t}"
end
