require 'JSON'

source_tweets = []

Dir.glob("/Users/sscott/Dropbox/tweets/data/js/tweets/*js") do |fname|
next unless fname == "/Users/sscott/Dropbox/tweets/data/js/tweets/2013_02.js"
  puts fname
  my_object = JSON.parse(IO.read(fname))
      source_tweets += my_object.map {|t| {id: t["id_str"], text: t["text"]} }

#  my_object.each do |h| puts "#{h["id_str"]} #{h["text"]}" end
end

source_tweets.each do |t|
  data = { "id" => t[:id], "text" => t[:text]}
  # Tweet.create!(data)
  puts data
end

 puts source_tweets
puts "#{source_tweets.length} tweets found"

