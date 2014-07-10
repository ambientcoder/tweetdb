
db = Connection.new.db('ruby-learning')
posts = db.collection('posts')

new_post = { :title => "RubyLearning.com, its awesome", :content => "This is a pretty sweet way to learn Ruby", :created_on => Time.now }
post_id = posts.insert(new_post)

post = Posts.find( :_id => post_id ).first
post[:author] = "Ethan Gunderson"
posts.update( { :_id => post_id }, post )

# or better

posts.update( { :_id => post_id }, '$set' => { :author => 'Ethan Gunderson' } )

posts.find.sort( [['_id', -1]] ).limit(5)
