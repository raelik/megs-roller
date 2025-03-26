module MEGS
  module Handlers
    # Does not inherit from base handler.
    class HealthCheck
      def initialize(_config, _request)
      end

      def call
        [200, { 'content-type' => 'text/plain' }, ['ok']]
      end
    end
  end
end
