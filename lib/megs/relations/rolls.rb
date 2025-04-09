#require 'rom-repository'
require 'date'
require 'json'
require 'base64'
require 'mmh3'

module MEGS
  module Entities
    class Roll < ROM::Struct
      # This bears explanation. To create a compact, unique search key of the primary
      # key (the timestamp and session_id), we concatenate the hexadecimal integer
      # timestamp (0-padded) with the session id, convert that string to actual binary
      # bytes, and get the base64-encoded representation of the binary blob.
      def raw_search_key
        Base64.encode64((timestamp.to_s(16).rjust(16,'0') + session_id).chars.
                        each_slice(2).to_a.map { |x| x.join.hex.chr }.join).strip
      end

      # This spits out the original timestamp and session_id
      def self.decode_search_key(search_key) 
        bytes = Base64.decode64(search_key).bytes
        [bytes[0..7].map { |x| x.to_s(16).rjust(2,'0') }.join.hex,
         bytes[8..-1].map { |x| x.to_s(16).rjust(2,'0') }.join]
      end

      # Just a MurmurHash3 hash of the search key
      def hash_key
        "%x" % Mmh3.hash128(raw_search_key)
      end

      def formatted_timestamp
        Time.at(timestamp / 10000000.0).to_datetime
      end
    end
  end

  module Relations
    class Rolls < ROM::Relation[:sql]
      JsonArray = Types::String.constructor(->(arr) { arr.to_json })
      Boolean   = Types::Integer.constructor(->(bool) { bool ? 1 : 0 })

      schema(:rolls, infer: true) do
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
