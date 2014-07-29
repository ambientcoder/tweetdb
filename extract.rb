require 'JSON'

Dir.glob("/Users/sscott/Downloads/tweets/data/js/tweets/*js") do |fname|
  puts fname
my_object = JSON.parse(IO.read(fname))
my_object.each do |h| puts "#{h["id_str"]} #{h["text"]}" end
  end

