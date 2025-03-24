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
        cs = row.each.with_index.reduce(0) do |sum, (v, i)|
          if i < start
            sum
          else
            megs[:total] >= v ? sum + 1 : sum
          end
        end unless start > Tables::MAX_INDEX

        # If we've hit the last column and still need to shift, start moving up.
        if (start + cs) > Tables::MAX_INDEX && megs[:total] > row[Tables::MAX_INDEX]
          cs += ((megs[:av_index] - 1)..1).step(-1).reduce(0) do |sum, i|
            v = Tables::ACTION_TABLE[i][Tables::MAX_INDEX]
            megs[:total] >= v ? sum + 1 : sum
          end unless (megs[:av_index] - 1) < 1

          # If you've somehow managed to roll above 120... here you go.
          cs += ((megs[:total] - 120) / 10.0).ceil if megs[:total] > 120
        end

        # Return the column shifts as a negative, since they become a bonus for
        # determining Result APs
        return cs * -1
      end

      def serve
        av, ov, ov_cs = params.values_at('av','ov','ov_cs').map(&:to_i)

        if params['result'] && !new_action?(av, ov, ov_cs) && megs[:total] >= megs[:target]
          megs[:cs] = calculate_cs
        else
          dice = roll
          sum  = dice.sum
          last = megs[:last_roll]

          # Only accept reroll requests if the action params haven't changes,
          # doubles were rolled, and the roll wasn't a 2.
          if params['reroll'] && !new_action?(av, ov, ov_cs) && last[0] == last[1] && last.first != 1
            megs[:total] = (sum == 2) ? 2 : megs[:total] + sum
          else
            megs[:av]    = av
            megs[:ov]    = ov
            megs[:ov_cs] = ov_cs
            megs[:total] = sum
            megs[:cs]    = 0
            megs[:raps]  = 0

            # A 2 is an automatic fail. Don't bother with the table.
            indexes, target_extra = Tables.get_action_indexes(av, ov, ov_cs) if sum != 2
            if indexes
              megs[:av_index] = indexes[0]
              megs[:ov_index] = indexes[1]
              megs[:target]   = Tables::ACTION_TABLE[indexes[0]][indexes[1]] + target_extra
            end
          end
          megs[:last_roll] = dice
        end

        [200, headers, [megs.to_json]]
      end
    end
  end
end
