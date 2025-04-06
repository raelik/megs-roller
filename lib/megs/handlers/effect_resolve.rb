require_relative 'base'

module MEGS
  module Handlers
    class EffectResolve < Base
      REQUIRED_PARAMS = %w(ev rv)

      def get
        ev, rv, rv_cs = params.values_at('ev', 'rv', 'rv_cs').map(&:to_i)
        megs.merge!(ev: ev, rv: rv, rv_cs: rv_cs)

        if megs[:success] && !megs[:resolved]
          cs = megs[:cs] + megs[:rv_cs]
          indexes, extra_raps = Tables.get_effect_indexes(ev, rv, cs)
          megs[:ev_index] = indexes[0]
          megs[:rv_index] = indexes[1]

          if indexes[1] == 0
            megs[:raps] = ev + extra_raps
          else
            result_aps = Tables::RESULT_TABLE[indexes[0]][indexes[1]]
            megs[:raps] = result_aps + extra_raps
          end
          megs[:resolved] = true
          log_roll
        end

        [200, headers, [megs.to_json]]
      end

      def log_fields
        megs.filter { |k| %i(av ov ov_cs target total success cs ev rv rv_cs raps).include?(k) }
      end
    end
  end
end
