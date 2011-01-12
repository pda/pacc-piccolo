if ENV['EXCEPTIONAL_KEY']
  require 'exceptional'
  use Rack::Exceptional, ENV['EXCEPTIONAL_KEY']
end

require 'rack-rewrite'
use Rack::Rewrite do

  %w{ /articles/feed /feed/atom /feed/ }.each do |path|
    r301 path, '/feed'
  end

  r301 %r{/articles(/\d+/.*)}, '$1'

  r301 %r{/(200\d/\d+)/\d+/(.*)}, '/$1/$2'

  r301 '/feed', 'http://feeds.feedburner.com/paulannesley',
    :if => Proc.new { |env| !(env['HTTP_USER_AGENT'] || '').match(/feed(burner|validator)/i) }

end

use Rack::Static, :urls => ['/static', '/assets', '/favicon.ico']

require './pacc'
run Sinatra::Application
