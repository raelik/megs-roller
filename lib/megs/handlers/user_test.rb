require 'megs/db'

module MEGS
  module Handlers
    # Does not inherit from base handler.
    class UserTest
      def initialize(_config, _request)
      end

      def call
        [200, { 'content-type' => 'text/plain' }, [users.to_a.inspect]]
      end

      def users
        MEGS::DB.rom.relations[:users]
      end
    end
  end
end
