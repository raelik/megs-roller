require 'rom'
require 'rom-sql'

module MEGS
  module Relations
    class Characters < ROM::Relation[:sql]
      schema(:characters, infer: true)
    end
  end
end
