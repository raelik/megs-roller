require_relative 'base'

module MEGS
  module Handlers
    class ActionRoll < Base
      REQUIRED_PARAMS = %w(av ov)

      def new_action?(av, ov, ov_cs)
        megs.empty? || megs.values_at(:av, :ov, :ov_cs) != [av, ov, ov_cs]
      end

      def roll
        rolls = []
        2.times do
          rolls << ((Random.rand(1000) + 1) % 10) + 1
        end
        rolls
      end

      def calculate_cs
        cs = 0
        return cs if megs[:target] == megs[:total]
        row = Tables::ACTION_TABLE[megs[:av_index]]

        # Don't count column shifts until you reach the CS Threshold value (11)
        start = megs[:target] < 11 ? Tables::CST_INDEXES[megs[:av_index]] : megs[:ov_index] + 1

        # Loop through the column and start counting column shifts. Don't bother
        # if we're already at the last column.
        cs = row[start..-1].reduce(0) { |sum, v| megs[:total] >= v ? sum + 1 : sum } unless start > Tables::MAX_INDEX

        # If we've hit the last column and still need to shift, start moving up.
        if (start + cs) > Tables::MAX_INDEX && megs[:total] > row[Tables::MAX_INDEX]
          # Grab the relevant last column values in reverse order
          last_col = Tables::MAX_INDEX[1..-1].transpose[-1][0..(megs[:av_index] - 2)].reverse
          cs += last_col.reduce(0) { |sum, v| megs[:total] >= v ? sum + 1 : sum } unless (megs[:av_index] - 1) < 1

          # If you've somehow managed to roll above 120... here you go.
          cs += ((megs[:total] - 120) / 10.0).ceil if megs[:total] > 120
        end

        # Return the column shifts as a negative, since they are applied as a penalty
        # to the RV.
        return cs * -1
      end

      def get
        av, ov, ov_cs, char_id = params.values_at('av','ov','ov_cs','c').map(&:to_i)
        megs.merge!(!session ? { user: nil, char: nil } : { user: session[:user][:id],
                                 char: session[:chars][char_id] ? char_id : 0 })

        if params['result'] && !new_action?(av, ov, ov_cs)
          megs[:success] = megs[:total] >= megs[:target]
          megs[:success] ? (megs[:cs] = calculate_cs) : log_roll
        elsif megs[:success].nil?
          dice = roll
          session[:current_rolls] << dice if session
          sum  = dice.sum
          last = megs[:last_roll]

          megs.merge!(av: av, ov: ov, ov_cs: ov_cs, cs: 0, raps: 0)

          indexes, target_extra = Tables.get_action_indexes(av, ov, ov_cs)
          if indexes
            megs.merge!(av_index: indexes[0], ov_index: indexes[1],
                        target: Tables::ACTION_TABLE[indexes[0]][indexes[1]] + target_extra)
          end

          # 2 is ALWAYS an automatic fail, even on a reroll.
          if sum == 2
            megs.merge!(success: false, total: sum)
            log_roll
          else
            # Only accept reroll requests if the action params haven't changes and doubles were rolled.
            if params['reroll'] && !new_action?(av, ov, ov_cs) && last[0] == last[1]
              megs[:total] = megs[:total] + sum
            else
              megs[:total] = sum
            end

            if dice[0] != dice[1]
              megs[:success] = megs[:total] >= megs[:target]
              megs[:success] ? (megs[:cs] = calculate_cs) : log_roll
            end
          end
          megs[:last_roll] = dice
        end

        [200, headers, [megs.to_json]]
      end

      def log_fields
        Hash[%w(av ov ov_cs).map { |k| [ k.to_sym, params[k] ]}].merge(
          megs.filter { |k| %i(target total success).include?(k) })
      end
    end
  end
end
