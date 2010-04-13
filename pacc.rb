%w{ sinatra piccolo }.each{ |r| require r }

include Piccolo

get '/' do
  @posts = PostCollection.new
  @links = LinkCollection.new
  @entries = (@posts.to_a + @links.to_a).sort
  haml :home
end

get %r{^/(\d{4})/(\d{2})/([\w-]+)$} do
  @post = PostCollection.new.post(*params[:captures])
  #@data = post.meta.merge(:post => @post, :content => @post.content)
  haml :post
end

get %r{^/([\w-]+)$} do
  stub = params[:captures].first
  haml :"pages/#{stub}"
end

# broken for now in 'sinatra' branch...
get '/feed' do
  posts, links = PostCollection.new, LinkCollection.new
  entries = (posts.to_a + links.to_a).sort
  if ENV['FEED_EPOCH']
    entries.delete_if { |e| e.time < Time.parse(ENV['FEED_EPOCH']) }
  end

  # thanks to http://github.com/cloudhead/toto
  feed = Builder::XmlMarkup.new :indent => 2
  feed.instruct!
  response.body = feed.feed "xmlns" => "http://www.w3.org/2005/Atom" do
    feed.title 'paul.annesley.cc'
    feed.id 'http://paul.annesley.cc/'
    feed.link :rel => 'self', :href => 'http://paul.annesley.cc/feed'
    feed.updated entries.first.time.gmtime.iso8601 unless entries.empty?
    feed.author { feed.name 'Paul Annesley' }
    entries.to_a[0...10].each do |entry|
      feed.entry do
        feed.id entry.meta['uid'] || entry.url
        feed.published entry.time.gmtime.iso8601
        feed.updated entry.time.gmtime.iso8601
        feed.title entry.title
        feed.link 'rel' => 'alternate', 'href' => entry.url
        feed.content entry.content, "type" => "html"
      end
    end
  end
  response['Content-Type'] = 'application/atom+xml'
end

