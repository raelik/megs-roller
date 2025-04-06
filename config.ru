$LOAD_PATH.unshift File.expand_path('lib', File.dirname(__FILE__))

require 'rubygems'
require 'rack/session/dalli'
require 'middleware/json_request_parser'
require 'rack/contrib/try_static'
require 'yaml'
require 'megs'

config = ENV['MEGS_SECRET'] ? { 'secret' => ENV['MEGS_SECRET'] } : YAML.load_file('config/config.yaml')

use Rack::Session::Dalli,
  memcache_server: ENV['MEGS_MEMCACHE'] || config['memcache_server'],
  pool_size: 3,
  key: 'sess',
  expire_after: 3600,
  httponly: false,
  skip: true

use Middleware::JsonRequestParser
use Rack::ContentLength
use Rack::TryStatic, urls: [''], root: 'public', index: 'index.html', try: ['.html','.css','.js','.ico']


MEGS::DB.configure(ENV['MEGS_DATABASE'] || config['database'])
run MEGS::Server.new(config)
