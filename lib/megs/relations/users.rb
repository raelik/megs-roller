require 'argon2id'

module MEGS
  module Relations
    class Users < ROM::Relation[:sql]
      schema(:users, infer: true) do
        attribute :admin, Types::Integer, read: Types::Params::Bool
        attribute :password, Types::String, read: Types.Constructor(Argon2id::Password, ->(pw) { Argon2id::Password.new(pw) })

        associations do
          has_many :characters
        end
      end
    end
  end
end
