%w{ sinatra haml builder ./piccolo }.each{ |r| require r }

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

get '/new' do
  haml :new, :layout => false
end

# post
get %r{^/(\d{4})/(\d{2})/([\w-]+)$} do
  begin
    @post = Piccolo::PostCollection.new.find(*params[:captures])
  rescue NameError
    pass
  end
  haml :post
end

# page
get %r{^/([\w-]+)$} do
  begin
    haml :"pages/#{params[:captures].first}"
  rescue Errno::ENOENT
    pass
  end
end

not_found do
  haml :not_found
end
