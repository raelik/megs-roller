require_relative 'base'
require 'megs/db'

module MEGS
  module Handlers
    class RollLog < Base
      def get
        log = []
        if session
          log = (MEGS::DB[:rolls].combine(:user, :character).order { timestamp.desc }.limit(50).to_a.map do |r|
            owner = (r.user.admin && r.character && (r.character.user_id != r.user.id)) ?
              MEGS::DB[:users].by_pk(r.character.user_id).first.name : r.user.name
            roll_fields = r.to_h.filter { |k| %i(av ov ov_cs target total success cs ev rv rv_cs raps rolls).include?(k) }
            { hash_key: r.hash_key, timestamp: r.timestamp.strftime('%Y-%m-%d %H:%M:%S.%7N %z'),
              user: r.user.name, character: r.character&.name, owner: owner }.merge(roll_fields)
          end)
        end
        [200, headers, [log.to_json]]
      end

      def megs
        false
      end
    end
  end
end 
