require 'piccolo'

use Rack::Static, :urls => ['/static', '/assets', '/favicon.ico']
run Piccolo::Server.new
