require 'rom'
require 'rom-sql'
require 'rom/sql/rake_task'
require 'yaml'

config = YAML.load_file('config/config.yaml')

namespace :db do
  task :setup do
    ROM::SQL::RakeSupport.env = ROM.container(:sql, config['database'])
  end
end
