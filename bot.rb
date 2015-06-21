# encoding: UTF-8

require 'rubygems'
require 'twitter'
require 'punkt-segmenter'
require 'twitter_init'
require 'variables'
require 'markov'
require 'htmlentities'
require 'uri'
require 'mongo'

include Mongo

class Tweet
  def self.create!(tweets)
    collection.insert(tweets)
  end

  def self.fetch
# get all rows {}. dont get _id field .get tweet field. map to ruby hash from mongo hash. map the tweet key values
    cursor = collection.find({},{:fields => {"_id" => 0, "text" => 1}}).map { |h| h["text"] }
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
  include_urls = $include_tweets_with_urls || params["include_urls"]
  include_replies = $include_replies || params["include_replies"]
  source_tweets = tweets.map {|t| html_decoder.decode(t).gsub(/\b(RT|MT) .+/, '') }

  if !include_urls
    source_tweets = source_tweets.reject {|t| t =~ /(https?:\/\/)/ }
  end

  if !include_replies
    source_tweets = source_tweets.reject {|t| t =~ /^@/ }
  end

# reject stphn.net links that will fail
  source_tweets = source_tweets.reject {|t| t =~ /stphn\.net/ }

  source_tweets.each do |t| 
#    t.gsub!(/(\#|(h\/t)|(http))\S+/, '')
    t.gsub!(/(@[\d\w_]+\s?)+/, '')
    t.gsub!(/[”“]/, '"')
    t.gsub!(/[‘’]/, "'")
    t.strip!
  end

  source_tweets
end

CLOSING_PUNCTUATION = ['.', ';', ':', '?', '!', ',']

def random_closing_punctuation
  CLOSING_PUNCTUATION[rand(CLOSING_PUNCTUATION.length)]
end

HASHTAG = ['#discuss', '#change', '#strategy', '#power', '#politics', '#art' , '#repetition', '#conceptual', '#slow', '#zen', '#future', '#oblique']

def random_hashtag
  HASHTAG.sample
#   '#' + File.read('/usr/share/dict/words').lines.sample
#   '#' + File.read('/usr/share/dict/words').lines.select {|l| (6..12).cover?(l.strip.size)}.sample.strip
end

source_tweets = []

$rand_limit ||= 10
$markov_index ||= 2

puts "random limit: #$rand_limit"
puts "markov index: #$markov_index"
puts "PARAMS: #{params}" if params.any?

unless params.key?("tweet")
  params["tweet"] = true
end

rand_key = rand($rand_limit)

# randomly running only about 1 in $rand_limit times
unless rand_key == 0 || params["force"]
  puts "Not running this time (key: #{rand_key})"
else

client = Twitter::REST::Client.new do |config|
  config.consumer_key = $consumer_key
  config.consumer_secret = $consumer_secret
  config.access_token = $access_token
  config.access_token_secret = $access_token_secret
end

user_tweets = Tweet.fetch
source_tweets += filtered_tweets(user_tweets)
  
puts "#{source_tweets.length} tweets found"

if source_tweets.length == 0
  raise "Error fetching tweets from Twitter. Aborting."
end
  
  markov = MarkovChainer.new($markov_index)

  tokenizer = Punkt::SentenceTokenizer.new(source_tweets.join(" "))  # init with corpus of all sentences

  source_tweets.each do |twt|
    next if twt.nil? || twt == ''
    sentences = tokenizer.sentences_from_text(twt, :output => :sentences_text)

    sentences.each do |sentence|
      next if sentence =~ /@/
      markov.add_sentence(sentence)
    end
  end
  
  tweet = nil
  
  10.times do
    tweet = markov.generate_sentence

    tweet_letters = tweet.gsub(/\P{Word}/, '')
    next if source_tweets.any? {|t| t.gsub(/\P{Word}/, '') =~ /#{tweet_letters}/ }

    if tweet.length < 40 && rand(10) == 0
      puts "Short tweet. Adding another sentence randomly"
      next_sentence = markov.generate_sentence
      tweet_letters = next_sentence.gsub(/\P{Word}/, '')
      next if source_tweets.any? {|t| t.gsub(/\P{Word}/, '') =~ /#{tweet_letters}/ }

      tweet += random_closing_punctuation if tweet !~ /[.;:?!),'"}\]\u2026]$/
      tweet += " #{markov.generate_sentence}"
    end

    if !params["tweet"]
      puts "MARKOV: #{tweet}"
    end

    break if !tweet.nil? && tweet.length < 110
  end
  
  tweet += random_closing_punctuation if tweet !~ /[.;:?!),'"}\]\u2026]$/

# format links properly ie, http t co as http://t.co
  tweet.gsub!(/https?.*t co /, 'http://t.co/')
  tweet.gsub!(/https?.*tumblr com /, 'http://tumblr.com/')
  tweet.gsub!(/https?.*bit ly /, 'http://bit.ly/')
  tweet.gsub!(/https?.*yfrog com /, 'http://yfrog.com/')

# remove trailing punctuation if tweet contains URLs
  tweet.gsub!(/\p{Punct}$/, '') if tweet =~ URI::regexp

# strip out any url unless requested
  tweet.gsub!(/http:\/\/.+/, '') unless $zentweet_includes_url

# add a random hashtag for 1 in 5 tweets if add_hashtag is true and if the tweet is less than 125 chars
# always add a hashtag if hashtag param is passed
  if !params["hashtag"]
    tweet += " #{random_hashtag}" if rand(5) == 0 && tweet.length < 125 && $add_hashtag
  else
    tweet += " #{random_hashtag}" if tweet.length < 125
  end
  tweet.strip!

  if params["tweet"]
    if !tweet.nil? && tweet != ''
      puts "TWEET: #{tweet}"
      client.update(tweet)
#    else
#      raise "ERROR: EMPTY TWEET"
    end
  else
    puts "DEBUG: #{tweet}"
  end
end

