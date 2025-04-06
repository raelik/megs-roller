require 'rom'
require 'rom-sql'

module MEGS
  module Relations
    class Characters < ROM::Relation[:sql]
      schema(:characters, infer: true) do
        associations do
          belongs_to :user
          has_many :rolls
        end
      end
    end
  end
end
