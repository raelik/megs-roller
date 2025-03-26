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
        av, ov, ov_cs = params.values_at('av','ov','ov_cs').map(&:to_i)

        if params['result'] && !new_action?(av, ov, ov_cs)
          megs[:success] = megs[:total] >= megs[:target]
          megs[:cs] = calculate_cs if megs[:success]
        elsif megs[:success].nil?
          dice = roll
          sum  = dice.sum
          last = megs[:last_roll]

          # 2 is ALWAYS an automatic fail, even on a reroll.
          if sum == 2
            megs[:success]  = false
            megs[:resolved] = true
            megs[:total]    = sum
          else
            # Only accept reroll requests if the action params haven't changes and doubles were rolled.
            if params['reroll'] && !new_action?(av, ov, ov_cs) && last[0] == last[1]
              megs[:total] = megs[:total] + sum
            else
              megs[:av]    = av
              megs[:ov]    = ov
              megs[:ov_cs] = ov_cs
              megs[:total] = sum
              megs[:cs]    = 0
              megs[:raps]  = 0

              indexes, target_extra = Tables.get_action_indexes(av, ov, ov_cs)
              if indexes
                megs[:av_index] = indexes[0]
                megs[:ov_index] = indexes[1]
                megs[:target]   = Tables::ACTION_TABLE[indexes[0]][indexes[1]] + target_extra
              end
            end
          end
          megs[:last_roll] = dice
        end

        [200, headers, [megs.to_json]]
      end
    end
  end
end
