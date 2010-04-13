%w{ sinatra piccolo builder }.each{ |r| require r }

get '/' do
  @entries = Piccolo::entries_all
  haml :home
end

get '/feed' do
  @entries = Piccolo::entries_all
  @entries.delete_if { |e| e.time < Time.parse(ENV['FEED_EPOCH']) } if ENV['FEED_EPOCH']
  content_type 'application/atom+xml', :charset => 'utf-8'
  builder :feed
end

# post
get %r{^/(\d{4})/(\d{2})/([\w-]+)$} do
  @post = Piccolo::PostCollection.new.find(*params[:captures])
  haml :post
end

# page
get %r{^/([\w-]+)$} do
  haml :"pages/#{params[:captures].first}"
end
