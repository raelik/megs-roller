module MEGS
  module Handlers
    # Does not inherit from base handler.
    class HealthCheck
      class << self
        def method_allowed?(method)
          method == 'GET'
        end

        def missing_params(_params)
          []
        end
      end

      attr_reader :request
      def initialize(_config, request)
        @request = request
      end


      def call
        [200, { 'content-type' => 'text/plain' }, ['ok']]
      end
    end
  end
end
