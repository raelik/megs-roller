require 'date'
require 'json'

module MEGS
  module Relations
    class Rolls < ROM::Relation[:sql]
      Timestamp = Types::Integer.constructor(->(ts) { (ts.to_f * 10000000).to_i })
      JsonArray = Types::String.constructor(->(arr) { arr.to_json })
      Boolean   = Types::Integer.constructor(->(bool) { bool ? 1 : 0 })

      schema(:rolls, infer: true) do
        attribute :timestamp, Timestamp, read: Types.Constructor(DateTime, ->(ts) { Time.at(ts / 10000000.0).to_datetime })
        attribute :success, Boolean, read: Types::Params::Bool
        attribute :rolls, JsonArray, read: Types.Constructor(Array, ->(r) { JSON.parse(r) })

        associations do
          belongs_to :user
          belongs_to :character
        end
      end
    end
  end
end
