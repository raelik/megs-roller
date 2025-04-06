# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table :rolls do
      column :timestamp, Integer, null: false
      column :session_id, String, null: false
      column :user_id, Integer, null: false
      column :character_id, Integer, null: true
      column :av, Integer, null: false
      column :ov, Integer, null: false
      column :ov_cs, Integer, null: true
      column :target, Integer, null: true
      column :rolls, String, null: false
      column :total, Integer, null: false
      column :success, Integer, null: false
      column :cs, Integer, null: true
      column :ev, Integer, null: true
      column :rv, Integer, null: true
      column :rv_cs, Integer, null: true
      column :raps, Integer, null: true
      primary_key [:timestamp, :session_id]
    end
  end
end
