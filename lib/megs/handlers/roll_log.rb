require_relative 'base'
require 'megs/db'
require 'openssl'

module MEGS
  module Handlers
    class RollLog < Base
      attr_reader :cipher
      def initialize(conf, req)
        super
        @cipher = (session ? OpenSSL::Cipher::AES.new(128, :CFB).encrypt : nil)
      end

      def get
        log = []
        if session
          search_ts, search_id = get_search_key
          rolls = MEGS::DB[:rolls].combine(:user, :character)
          rolls = (search_ts.nil? ? rolls.order { [ timestamp.desc, session_id.desc ] } :
                                    rolls.where { timestamp >= search_ts }.
                                          where { !(timestamp.is(search_ts) & session_id.is(search_id)) }.
                                          order { [ timestamp.asc, session_id.asc ] }).limit(50)

          log = (rolls.to_a.map do |r|
            owner = (r.user.admin && r.character && (r.character.user_id != r.user.id)) ?
              MEGS::DB[:users].by_pk(r.character.user_id).first.name : r.user.name
            roll_fields = r.to_h.filter { |k| %i(av ov ov_cs target total success cs ev rv rv_cs raps rolls).include?(k) }
            { hash_key: r.hash_key, timestamp: r.formatted_timestamp.strftime('%Y-%m-%d %H:%M:%S.%7N %z'),
              user: r.user.name, character: r.character&.name, owner: owner, search_key: generate_search_key(r)}.merge(roll_fields)
          end)
        end
        [200, headers, [log.to_json]]
      end

      def megs
        false
      end

      private

      def get_search_key
        if encrypted = (Base64.urlsafe_decode64(request.get_header('HTTP_X_MEGS_SEARCH_KEY')) rescue nil)
          cipher.decrypt
          cipher.key = session[:cipher][:key]
          cipher.iv  = session[:cipher][:iv]
          MEGS::Entities::Roll.decode_search_key(cipher.update(encrypted) + cipher.final)
        end
      ensure
        cipher.reset
        cipher.encrypt
        cipher.key = session[:cipher][:key]
        cipher.iv  = session[:cipher][:iv]
      end

      def generate_search_key(roll)
        plain = roll.raw_search_key
        Base64.urlsafe_encode64(cipher.update(plain) + cipher.final, padding: false)
      ensure
        cipher.reset
        cipher.encrypt
        cipher.key = session[:cipher][:key]
        cipher.iv  = session[:cipher][:iv]
      end
    end
  end
end 
