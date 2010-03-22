require 'piccolo'
require 'rack-rewrite'

# legacy URL support
use Rack::Rewrite do
  %w{ /articles/feed /feed/atom /feed/ }.each do |path|
    r301 path, '/feed'
  end
  r301 %r{/articles(/\d+/.*)}, '$1'
end

use Rack::Static, :urls => ['/static', '/assets', '/favicon.ico']

run Piccolo::Server.new
