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

# Turn off keepalive support for better long tails response time with Router 2.0
# Remove this line when https://github.com/puma/puma/issues/3487 is closed, and the fix is released
enable_keep_alives(false) if respond_to?(:enable_keep_alives)

rackup      DefaultRackup if defined?(DefaultRackup)
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  MEGS::DB.connect if MEGS::DB.config
end

on_worker_shutdown do
  MEGS::Handlers::Base.pool.shutdown
  MEGS::Handlers::Base.pool.wait_for_termination
end
