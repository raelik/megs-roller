require 'megs/tables'
require 'megs/error'
require 'megs/handlers'
require 'rack/utils'
require 'json'

module MEGS
  class Server
    ROUTES = {
      '/action_roll' => Handlers::ActionRoll,
      '/effect_resolve' => Handlers::EffectResolve,
      '/health' => Handlers::HealthCheck,
      '/login' => Handlers::Login,
      '/logout' => Handlers::Login
    }.freeze

    attr_reader :config
    def initialize(conf)
      @config = conf
      Handlers::Login.setup(conf)
    end

    def validate_request(env)
      r = Rack::Request.new(env)
      h = ROUTES[r.path_info]
      raise Error.new(404, "File not found: #{r.path_info}") unless h
      h.new(config, r)
    end

    def call(env)
      handler = validate_request(env)
      handler.call
    rescue Error => e
      [e.status, {}, [e.message]]
    rescue => e
      puts "[%d] %s - %s" % [Process.pid, env['REMOTE_ADDR'], "ERROR: #{e.message}"]
      e.backtrace.each { |line| puts line }
      [500, {}, ["Internal Server Error"]]
    end
  end
end
