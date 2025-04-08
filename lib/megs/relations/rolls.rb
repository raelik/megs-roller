#require 'rom-repository'
require 'date'
require 'json'
require 'base64'
require 'mmh3'

module MEGS
  module Entities
    class Roll < ROM::Struct
      def hash_key
        # This bears explanation. To create a compact, unique hash key of the primary
        # key (the timestamp and session_id), we convert the timestamp to milliseconds,
        # concatenate its 0-padded hex representation with the session id, convert that
        # string to actual binary bytes, get the base64-encoded representation of THAT
        # binary blob, then spit out a hex-encoded MurmurHash3 of said base64. Phew.
        "%x" % Mmh3.hash128(Base64.encode64(('0'+ ('%x' % (timestamp.to_time.to_f * 1000000).to_i) + session_id).upcase.
                                            chars.each_slice(2).to_a.map { |x| "0x#{x.join}".to_i(16).chr }.join))
      end
    end
  end

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

      struct_namespace MEGS::Entities
      auto_struct true
    end
  end
end
