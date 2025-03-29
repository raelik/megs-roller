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
      '/user_test' => Handlers::UserTest
    }.freeze

    attr_reader :config
    def initialize(config)
      @config = config
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
    end
  end
end
