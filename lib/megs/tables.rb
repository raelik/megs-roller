module MEGS
  module Tables
    RANGE_INDEXES = [0, 1..2, 3..4, 5..6, 7..8, 9..10, 11..12, 13..15, 16..18, 19..21,
                     22..24, 25..27, 28..30, 31..35,  36..40, 41..45, 46..50, 51..55,
                     56..60, 61..68, 69..76, 77..84, 85..92, 93..100].freeze
    MAX_INDEX = (RANGE_INDEXES.size - 1).freeze

    ACTION_TABLE = [ nil, # There is no zero row
     # 0   2   4   6   8  10  12  15  18  21  24  27  30  35  40  45  50  55  60  68  76   84   92  100
      [6, 11, 13, 15, 18, 21, 24, 28, 32, 36, 40, 45, 50, 55, 60, 65, 70, 75, 80, 88, 96, 104, 112, 120], # 1-2
      [5,  9, 11, 13, 15, 18, 21, 24, 28, 32, 36, 40, 45, 50, 55, 60, 65, 70, 75, 80, 88,  96, 104, 112], # 3-4
      [4,  7 , 9, 11, 13, 15, 18, 21, 24, 28, 32, 36, 40, 45, 50, 55, 60, 65, 70, 75, 80,  88,  96, 104], # 5-6
      [4,  5,  7,  9, 11, 13, 15, 18, 21, 24, 28, 32, 36, 40, 45, 50, 55, 60, 65, 70, 75,  80,  88,  96], # 7-8
      [3,  4,  5,  7,  9, 11, 13, 15, 18, 21, 24, 28, 32, 36, 40, 45, 50, 55, 60, 65, 70,  75,  80,  88], # 9-10
      [3,  3,  4,  5,  7,  9, 11, 13, 15, 18, 21, 24, 28, 32, 36, 40, 45, 50, 55, 60, 65,  70,  75,  80], # 11-12
      [3,  3,  3,  4,  5,  7,  9, 11, 13, 15, 18, 21, 24, 28, 32, 36, 40, 45, 50, 55, 60,  65,  70,  75], # 13-15
      [3,  3,  3,  3,  4,  5,  7,  9, 11, 13, 15, 18, 21, 24, 28, 32, 36, 40, 45, 50, 55,  60,  65,  70], # 16-18
      [3,  3,  3,  3,  3,  4,  5,  7,  9, 11, 13, 15, 18, 21, 24, 28, 32, 36, 40, 45, 50,  55,  60,  65], # 19-21
      [3,  3,  3,  3,  3,  3,  4,  5,  7,  9, 11, 13, 15, 18, 21, 24, 28, 32, 36, 40, 45,  50,  55,  60], # 22-24
      [3,  3,  3,  3,  3,  3,  3,  4,  5,  7,  9, 11, 13, 15, 18, 21, 24, 28, 32, 36, 40,  45,  50,  55], # 25-27
      [3,  3,  3,  3,  3,  3,  3,  3,  4,  5,  7,  9, 11, 13, 15, 18, 21, 24, 28, 32, 36,  40,  45,  50], # 28-30
      [3,  3,  3,  3,  3,  3,  3,  3,  3,  4,  5,  7,  9, 11, 13, 15, 18, 21, 24, 28, 32,  36,  40,  45], # 31-35
      [3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  4,  5,  7,  9, 11, 13, 15, 18, 21, 24, 28,  32,  36,  40], # 36-40
      [3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  4,  5,  7,  9, 11, 13, 15, 18, 21, 24,  28,  32,  36], # 41-45
      [3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  4,  5,  7,  9, 11, 13, 15, 18, 21,  24,  28,  32], # 46-50
      [3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  4,  5,  7,  9, 11, 13, 15, 18,  21,  24,  28], # 51-55
      [3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  4,  5,  7,  9, 11, 13, 15,  18,  21,  24], # 56-60
      [3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  4,  5,  7,  9, 11, 13,  15,  18,  21], # 61-68
      [3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  4,  5,  7,  9, 11,  13,  15,  18], # 69-76
      [3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  4,  5,  7,  9,  11,  13,  15], # 77-84
      [3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  4,  5,  7,   9,  11,  13], # 85-92
      [3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  4,  5,   7,   9,  11], # 93-100
    ].freeze
    CST_INDEXES = ([nil] + 23.times.map { |x| x + 1 }).freeze

    RESULT_TABLE = [ nil, # There is no zero row
      [:all,  1],
      [:all,  2,  1],
      [:all,  3,  2,  1],
      [:all,  5,  4,  3,  2],
      [:all,  8,  6,  4,  3,  2],
      [:all, 10,  9,  7,  6,  4,  3],
      [:all, 12, 11,  9,  8,  7,  5,  3],
      [:all, 14, 13, 11, 10,  9,  8,  6,  4],
      [:all, 18, 17, 16, 14, 12, 10,  8,  6,  4],
      [:all, 21, 20, 19, 17, 16, 13, 11,  9,  7,  5],
      [:all, 24, 23, 22, 20, 18, 16, 14, 12, 10,  8,  6],
      [:all, 27, 26, 25, 23, 21, 19, 17, 15, 13, 11,  9,  7],
      [:all, 30, 29, 28, 26, 24, 22, 20, 18, 16, 14, 12, 10,  8],
      [:all, 35, 34, 33, 31, 29, 27, 25, 23, 21, 19, 17, 14, 12,  9],
      [:all, 40, 38, 36, 34, 32, 30, 28, 26, 24, 22, 20, 18, 16, 13, 10],
      [:all, 45, 43, 41, 40, 38, 36, 34, 31, 28, 26, 24, 22, 20, 17, 14, 11],
      [:all, 50, 48, 46, 44, 42, 40, 38, 36, 34, 32, 30, 27, 24, 21, 18, 15, 12],
      [:all, 55, 53, 51, 49, 47, 45, 43, 41, 39, 36, 33, 30, 27, 24, 21, 18, 15, 13],
      [:all, 60, 58, 56, 54, 52, 50, 48, 46, 43, 40, 37, 34, 31, 28, 25, 22, 19, 16, 14],
      [:all, 68, 66, 64, 62, 60, 58, 56, 53, 50, 47, 44, 41, 38, 35, 32, 29, 26, 23, 19, 16],
      [:all, 76, 74, 72, 70, 68, 66, 62, 58, 54, 51, 48, 45, 42, 39, 36, 33, 30, 27, 24, 21, 18],
      [:all, 84, 82, 80, 78, 76, 74, 70, 66, 62, 59, 56, 53, 50, 47, 44, 41, 37, 33, 29, 26, 23, 20],
      [:all, 92, 90, 88, 86, 84, 82, 78, 74, 70, 67, 64, 61, 58, 55, 51, 47, 43, 39, 35, 31, 28, 25, 22]
    ].map { |row| row.nil? ? nil : row + ([0] * (24 - row.size)) }.freeze

    def self.get_range_index(value)
      if value > RANGE_INDEXES.last.max
        extra = ((value - RANGE_INDEXES.last.max) / 10.0).ceil
        MAX_INDEX + extra
      else
        RANGE_INDEXES.index { |x| x.kind_of?(Range) ? x.include?(value) : x == value }
      end
    end

    def self.get_indexes(x, y, y_mod)
      indexes = [x, y].map { |v| get_range_index(v) }
      indexes[1] = indexes[1] + y_mod
      indexes
    end

    def self.get_effect_indexes(ev, rv, rv_cs)
      indexes = get_indexes(ev, rv, rv_cs)

      # Handle RV > 100
      if indexes[1] > MAX_INDEX
        if indexes[0] == indexes[1]
          indexes[0] = MAX_INDEX
          indexes[1] = MAX_INDEX
        else
          diff = indexes[1] - MAX_INDEX
          indexes[1] = MAX_INDEX
          indexes[0] -= diff
          indexes[0] = 1 if indexes[0] < 1
        end
      end

      # Handle RV < 0 and EV > 100
      extra_raps = 0
      if indexes[1] < 0
        extra_raps = indexes[1].abs
        indexes[1] = 0
      elsif indexes[0] > MAX_INDEX
        extra_raps = (indexes[0] - MAX_INDEX) * 10
        indexes[0] = MAX_INDEX
      end
      [indexes, extra_raps]
    end

    def self.get_action_indexes(av, ov, ov_cs)
      indexes = get_indexes(av, ov, ov_cs)
      indexes[1] = 0 if indexes[1] < 0

      # Handle AV > 100
      if indexes[0] > MAX_INDEX
        if indexes[0] == indexes[1]
          indexes[0] = MAX_INDEX
          indexes[1] = MAX_INDEX
        else
          diff = indexes[0] - MAX_INDEX
          indexes[0] = MAX_INDEX
          indexes[1] -= diff
          indexes[1] = 0 if indexes[1] < 0
        end
      end

      # Handle OV > 100
      target_extra = 0
      if indexes[1] > MAX_INDEX
        row_shift = indexes[1] - MAX_INDEX
        indexes[1] = MAX_INDEX
        if indexes[0] - row_shift >= 1
          indexes[0] -= row_shift
        else
          target_extra = (row_shift  - (indexes[0] - 1)) * 10
          indexes[0] = 1
        end
      end
      [indexes, target_extra]
    end
  end
end
