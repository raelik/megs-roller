module MEGS
  module Relations
    class Users < ROM::Relation[:sql]
      schema(:users, infer: true) do
        attribute :admin, Types::Integer, read: Types::Params::Bool
      end
    end
  end
end
