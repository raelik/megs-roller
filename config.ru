$LOAD_PATH.unshift File.expand_path('lib', File.dirname(__FILE__))

require 'rubygems'
require 'rack/session/dalli'
require 'middleware/json_request_parser'
require 'rack/contrib/try_static'
require 'yaml'
require 'megs'

config = ENV['MEGS_SECRET'] ? { 'secret' => ENV['MEGS_SECRET'] } : YAML.load_file('config/config.yaml')
config['login'] = (ENV['MEGS_LOGIN'] || config['login']) unless (ENV['MEGS_LOGIN'] && config['login']).to_s.empty?

db_config = ENV['MEGS_DATABASE'] || config['database']
MEGS::DB.configure(db_config) if db_config

memcache_server = ENV['MEGS_MEMCACHE'] || config['memcache_server']
use(Rack::Session::Dalli,
  memcache_server: memcache_server,
  pool_size: 3,
  key: 'sess',
  expire_after: 3600,
  httponly: false,
  skip: true) if db_config && memcache_server

use Middleware::JsonRequestParser
use Rack::ContentLength
use Rack::TryStatic, urls: [''], root: 'public', index: 'index.html', try: ['.html','.css','.js','.ico','.png']

webhook_url = ENV['MEGS_WEBHOOK'] || config['webhook_url']
MEGS::Handlers::Base.setup(webhook_url) if db_config && webhook_url
run MEGS::Server.new(config)
