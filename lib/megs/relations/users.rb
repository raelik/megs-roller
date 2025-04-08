require 'argon2id'

module MEGS
  module Entities
    class User < ROM::Struct
    end
  end

  module Relations
    class Users < ROM::Relation[:sql]
      Boolean  = Types::Integer.constructor(->(bool) { bool ? 1 : 0 })
      Password = Types::String.constructor(->(pw) { Argon2id::Password.create(pw).to_s })

      schema(:users, infer: true) do
        attribute :admin, Boolean, read: Types::Params::Bool
        attribute :password, Password, read: Types.Constructor(Argon2id::Password)

        associations do
          has_many :characters
          has_many :rolls
        end
      end

      struct_namespace MEGS::Entities
      auto_struct true
    end
  end
end
