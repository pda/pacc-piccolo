require 'rack-rewrite'
#require 'exceptional'

#use Rack::Exceptional, 'd2e3909172e0a9467c838355f87a1ca2936cb3f6'

# legacy URL support
use Rack::Rewrite do

  %w{ /articles/feed /feed/atom /feed/ }.each do |path|
    r301 path, '/feed'
  end

  r301 %r{/articles(/\d+/.*)}, '$1'

  r301 '/feed', 'http://feeds.feedburner.com/paulannesley',
    :if => Proc.new { |env| !env['HTTP_USER_AGENT'].match(/feed(burner|validator)/) }

end

use Rack::Static, :urls => ['/static', '/assets', '/favicon.ico']

require 'pacc'
run Sinatra::Application
