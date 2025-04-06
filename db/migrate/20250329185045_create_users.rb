# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :users do
      primary_key :id
      column :username, String, null: false, unique: true
      column :name, String, null: false
      column :password_hash, String, null: false
      column :admin, Integer, null: false, default: 0
    end
  end
end
