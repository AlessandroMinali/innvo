# frozen_string_literal: true
require 'rack/smack'

use Rack::Smack
use Rack::Deflater

require './poll'
run Sinatra::Application
