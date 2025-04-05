$LOAD_PATH.unshift File.expand_path('lib', File.dirname(__FILE__))

require 'rubygems'
require 'middleware/json_request_parser'
require 'rack/contrib/try_static'
require 'yaml'
require 'megs'

use Middleware::JsonRequestParser
use Rack::ContentLength
use Rack::TryStatic, urls: [''], root: 'public', index: 'index.html', try: ['.html','.css','.js','.ico']

config = ENV['MEGS_SECRET'] ? { 'secret' => ENV['MEGS_SECRET'] } : YAML.load_file('config/config.yaml')

MEGS::DB.configure(ENV['MEGS_DB'] || config['database'])
run MEGS::Server.new(config)
