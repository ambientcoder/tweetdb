# encoding: UTF-8

require 'rubygems'
require './twitter_init'
require './variables'
require 'mongo'
require 'JSON'

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

    def self.db
      @db ||= establish_connection
    end

    def self.collection
      @collection ||= db.collection("tweets")
    end
end

def filtered_tweets(tweets)
    # source_tweets = tweets.map {|t| {id: t.id, text: t.text} }
    # source_tweets = tweets.map {|t| {id: t["id"], text: t["text"]} }
end

Dir.glob("/Users/sscott/Dropbox/tweets/data/js/tweets/*js") do |fname|
  # next unless fname == "/Users/sscott/Downloads/tweets/data/js/tweets/2013_02.js"
  
  my_object = JSON.parse(IO.read(fname))
  # my_object.each do |h|
  # source_tweets += filtered_tweets(h)
  # end
  source_tweets += my_object.map {|t| {id: t["id"], text: t["text"]} }    
end 
  
if source_tweets.length == 0
  raise "Error fetching tweets from Twitter. Aborting."
end
  
source_tweets.each do |t|
  data = { "id" => t[:id], "text" => t[:text]}
  Tweet.create!(data)
  # puts data
end

puts "#{source_tweets.length} tweets found"

