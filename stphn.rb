require "tweetstream"
require "mongo"
require "time"

db = Mongo::Connection.new.db("stphn")
tweets = db.collection("tweets")

TweetStream::Daemon.new("TWITTER_USER", "TWITTER_PASS", "scrapedaemon").on_error do |message|
  # Log your error message somewhere
end.filter({"locations" => "-12.72216796875, 49.76707407366789, 1.977539, 61.068917"}) do |status|
  # Do things when nothing's wrong
  data = {"created_at" => Time.parse(status.created_at), "text" => status.text, "geo" => status.geo, "coordinates" => status.coordinates, "id" => status.id, "id_str" => status.id_str}
  tweets.insert({"data" => data});
end
