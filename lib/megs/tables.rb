module MEGS
  module Tables
    RANGE_INDEXES = %w(0 2 4 6 8 10 12 15 18 21 24 27 30
                       35 40 45 50 55 60 68 76 84 92 100).map(&:to_i)
    MAX_INDEX = (RANGE_INDEXES.size - 1).freeze

    RANGE_INDEXES.map!.with_index do |x, i|
      prev = RANGE_INDEXES[i-1]
      prev = (prev.kind_of?(Range) ? prev.last : prev) + 1
      x == 0 ? x : Range.new(prev, x)
    end.freeze

    ACTION_BASE = %w(11 13 15 18 21 24 28 32 36 40 45 50 55 60 65 70 75 80 88 96 104 112 120).map(&:to_i).freeze
    ACTION_TABLE = [ nil, # There is no zero row
      [6], [5, 9], [4, 7, 9], [4, 5, 7, 9] ]
    23.times do |x|
      i = x + 1
      if x < 4
        ACTION_TABLE[i] += ACTION_BASE[0..(i * -1)]
      else
        ACTION_TABLE[i] = ([3] * (x - 3)) + [4, 5, 7, 9] + ACTION_BASE[0..(i * -1)]
      end
    end
    ACTION_TABLE.freeze

    RESULT_TABLE = [ nil, [1], [2, 1], [3, 2, 1], [5, 4, 3, 2], [8, 6, 4, 3, 2], [10, 9, 7, 6, 4, 3], [12, 11, 9, 8, 7, 5, 3], [14, 13, 11,
      10, 9, 8, 6, 4], [18, 17, 16, 14, 12, 10, 8, 6, 4], [21, 20, 19, 17, 16, 13, 11, 9, 7, 5], [24, 23, 22, 20, 18, 16, 14, 12, 10, 8, 6],
      [27, 26, 25, 23, 21, 19, 17, 15, 13, 11, 9, 7], [30, 29, 28, 26, 24, 22, 20, 18, 16, 14, 12, 10, 8], [35, 34, 33, 31, 29, 27, 25, 23,
      21, 19, 17, 14, 12, 9], [40, 38, 36, 34, 32, 30, 28, 26, 24, 22, 20, 18, 16, 13, 10], [45, 43, 41, 40, 38, 36, 34, 31, 28, 26, 24, 22,
      20, 17, 14, 11], [50, 48, 46, 44, 42, 40, 38, 36, 34, 32, 30, 27, 24, 21, 18, 15, 12], [55, 53, 51, 49, 47, 45, 43, 41, 39, 36, 33,
      30, 27, 24, 21, 18, 15, 13], [60, 58, 56, 54, 52, 50, 48, 46, 43, 40, 37, 34, 31, 28, 25, 22, 19, 16, 14], [68, 66, 64, 62, 60, 58,
      56, 53, 50, 47, 44, 41, 38, 35, 32, 29, 26, 23, 19, 16], [76, 74, 72, 70, 68, 66, 62, 58, 54, 51, 48, 45, 42, 39, 36, 33, 30, 27, 24,
      21, 18], [84, 82, 80, 78, 76, 74, 70, 66, 62, 59, 56, 53, 50, 47, 44, 41, 37, 33, 29, 26, 23, 20], [92, 90, 88, 86, 84, 82, 78, 74,
      70, 67, 64, 61, 58, 55, 51, 47, 43, 39, 35, 31, 28, 25, 22]]
    23.times do |x|
      i = x + 1
      RESULT_TABLE[i] += ([nil] * (23 - i))
      RESULT_TABLE[i].unshift(:all)
    end
    RESULT_TABLE.freeze

    def self.get_index(value)
      if value > RANGE_INDEXES.last.max
        extra = ((value - RANGE_INDEXES.last.max) / 10.0).ceil
        MAX_INDEX + extra
      else
        RANGE_INDEXES.index { |x| x.kind_of?(Range) ? x.include?(value) : x == value }
      end
    end
  end
end
