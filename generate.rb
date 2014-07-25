# encoding: UTF-8

require 'rubygems'
require 'twitter'
require './twitter_init'
require './variables'
require 'mongo'
require 'htmlentities'

source_tweets = []

class Tweet
  def self.create!(tweets)
    collection.insert(tweets)
  end

  private
    def self.establish_connection
      Mongo::Connection.new.db("twitter")
    end

    def self.db
      @db ||= establish_connection
    end

    def self.collection
      @collection ||= db.collection("tweets")
    end
end

##puts "PARAMS: #{params}" if params.any?

def filtered_tweets(tweets)
 # html_decoder = HTMLEntities.new
  include_urls = $include_urls || params["include_urls"]
  include_replies = $include_replies || params["include_replies"]
  ##source_tweets = tweets.map {|t| html_decoder.decode(t.text).gsub(/\b(RT|MT) .+/, '') }
  source_tweets = tweets.map {|t| {id: t.id, text: t.text} }

  if !include_urls
    source_tweets = source_tweets.reject {|t| t =~ /(https?:\/\/)/ }
  end

  if !include_replies
    source_tweets = source_tweets.reject {|t| t =~ /^@/ }
  end

  ##source_tweets.each do |t| 
  ##  t.gsub!(/(\#|(h\/t)|(http))\S+/, '')
  ##  t.gsub!(/(@[\d\w_]+\s?)+/, '')
  ##  t.gsub!(/[”“]/, '"')
  ##  t.gsub!(/[‘’]/, "'")
  ##  t.strip!
  #  t << "." if t !~ /[.,?;:!'"\])\u2026]$/
  ##end

  source_tweets
end

client = Twitter::REST::Client.new do |config|
  config.consumer_key = $consumer_key
  config.consumer_secret = $consumer_secret
  config.access_token = $access_token
  config.access_token_secret = $access_token_secret
end

  # Fetch a thousand tweets
  begin
    user_tweets = client.user_timeline($source_account, :count => 20, :trim_user => true, :include_rts => false)
    max_id = user_tweets.last.id

#puts "ATTRS"
#puts user_tweets.first.attrs
#puts "METHODS"
#puts user_tweets.first.methods
#    puts user_tweets.first.text
#    puts user_tweets.first.id
#    puts user_tweets.first.retweet_count
#    puts user_tweets.first.retweeted?
#    puts user_tweets.first.favorited?
#    puts user_tweets.first.attrs[:id_str]

    source_tweets += filtered_tweets(user_tweets)
  
    # Twitter only returns up to 3200 of a user timeline, includes retweets.
#    17.times do
#      user_tweets = client.user_timeline($source_account, :count => 200, :trim_user => true, :include_rts => false, :max_id => max_id - 1)
#      puts "MAX_ID #{max_id} TWEETS: #{user_tweets.length}"
#      break if user_tweets.last.nil?
#      max_id = user_tweets.last.id
#      source_tweets += filtered_tweets(user_tweets)
#    end
#  rescue => ex
#    puts ex.message
  end
  
  puts "#{source_tweets.length} tweets found"

  if source_tweets.length == 0
    raise "Error fetching tweets from Twitter. Aborting."
  end
  
source_tweets.each do |t|
  data = { "id" => t[:id], "text" => t[:text]}
puts data
#puts "#{t[:id]} XX #{t[:text]}"
#  data = { "tweet" => t}
#  Tweet.create!(data)
end
