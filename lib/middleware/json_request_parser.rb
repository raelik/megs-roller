require 'rack'
require 'json'

module Middleware

  # A Rack middleware for parsing POST/PUT body data when Content-Type is <tt>application/json</tt>.
  class JsonRequestParser
    # Supported Content-Types
    #
    APPLICATION_JSON = 'application/json'.freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      req = Rack::Request.new(env)

      if req.media_type == APPLICATION_JSON && (body = env[Rack::RACK_INPUT].read).length != 0
        env[Rack::RACK_INPUT].rewind # somebody might try to read this stream
        env.update(Rack::RACK_REQUEST_FORM_HASH => JSON.parse(body, :create_additions => false),
                   Rack::RACK_REQUEST_FORM_INPUT => env[Rack::RACK_INPUT])
      end
      @app.call(env)
    rescue JSON::ParserError => e
      bad_request(message: 'Failed to parse body as JSON')
    end

    def bad_request(body = { message: 'Bad Request' })
      json = body.to_json
      [ 400, { Rack::CONTENT_TYPE => APPLICATION_JSON, Rack::CONTENT_LENGTH => json.size.to_s }, [json] ]
    end
  end
end
