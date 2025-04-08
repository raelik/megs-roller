require 'rom'
require 'rom-sql'

module MEGS
  module Entities
    class Character < ROM::Struct
    end
  end

  module Relations
    class Characters < ROM::Relation[:sql]
      schema(:characters, infer: true) do
        associations do
          belongs_to :user
          has_many :rolls
        end
      end

      struct_namespace MEGS::Entities
      auto_struct true
    end
  end
end
