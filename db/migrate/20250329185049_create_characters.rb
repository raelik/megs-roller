# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :characters do
      primary_key :id
      column :name, String, null: false
      foreign_key :user_id, :users, null: false
    end

    alter_table :characters do
      add_unique_constraint [:name, :user_id]
    end
  end
end
