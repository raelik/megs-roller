require_relative 'base'

module MEGS
  module Handlers
    class EffectResolve < Base
      REQUIRED_PARAMS = %w(ev rv)

      def serve
        ev, rv, rv_cs = params.values_at('ev','rv','rv_cs').map(&:to_i)

        headers = { 'content-type' => 'application/json' }
        [200, headers, ['']]
      end
    end
  end
end
