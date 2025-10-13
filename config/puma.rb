$LOAD_PATH.unshift File.expand_path('../lib', File.dirname(__FILE__))
require 'megs/db'
require 'megs/handlers/base'

workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = 5
threads threads_count, threads_count
log_requests true

preload_app!

# Support IPv6 by binding to host `::` instead of `0.0.0.0`
port (ENV['PORT'] || 3000), "::"

rackup      DefaultRackup if defined?(DefaultRackup)
environment ENV['RACK_ENV'] || 'development'

before_worker_boot do
  MEGS::DB.connect if MEGS::DB.config
end

before_worker_shutdown do
  MEGS::Handlers::Base.pool.shutdown
  MEGS::Handlers::Base.pool.wait_for_termination
end
