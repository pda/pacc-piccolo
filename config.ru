require 'piccolo'

use Rack::Static, :urls => ['/static']
use Rack::CommonLogger

piccolo = Piccolo::Server.new

run piccolo
