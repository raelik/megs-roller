$LOAD_PATH.unshift File.expand_path('lib', File.dirname(__FILE__))

require 'rubygems'
require 'rack/static'
require 'yaml'
require 'megs'

use Rack::ContentLength
use Rack::Static, urls: [''], root: 'public', index: 'index.html', cascade: true

run MEGS::Server.new(YAML.load_file('config/config.yaml'))
