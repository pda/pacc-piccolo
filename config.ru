require 'piccolo'

use Rack::Static, :urls => ['/static']
run Piccolo::Server.new
