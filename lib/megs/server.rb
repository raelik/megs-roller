require 'megs/tables'
require 'megs/error'
require 'megs/handlers'
require 'rack/utils'
require 'json'

module MEGS
  class Server
    VALID_PATHS = {
      '/action_roll' => Handlers::ActionRoll,
      '/effect_resolve' => Handlers::EffectResolve
    }.freeze

    attr_reader :config
    def initialize(config)
      @config = config
    end

    def validate_request(env)
      r = Rack::Request.new(env)
      h = VALID_PATHS[r.path_info]
      raise Error.new(404, "File not found: #{r.path_info}") unless h
      raise Error.new(405, "Method #{r.method} not allowed for #{r.path_info}") unless h.method_allowed?(r.request_method)
      missing = h.missing_params(r.params)
      raise Error.new(400, "missing required param: #{missing.join(', ')}") unless missing.empty?
      h.new(config, r)
    end

    def call(env)
      handler = validate_request(env)
      handler.call
    end
  end
end
