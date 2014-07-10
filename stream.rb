require 'mongo'
require 'twitter-text'

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

Twitter.stream("mytwittername", "secret") do |status|
  Tweet.create!(status)
end

collection.find(:user => { :screen_name => "glenngillen" })

#
# data returned as follows
# 
#{ :user => { :screen_name => "glenngillen", 
#             :profile_image_url => "http://rubypond.com/image.png",
#             :followers_count => 1000000 },
#  :text => "This is the text from my tweet"
#}
