# frozen_string_literal: true

class CreateApiLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :api_logs do |t|
      t.string :path, null: false, limit: 255
      t.string :request_method, null: false, limit: 10
      t.integer :status, null: false
      t.references :user, foreign_key: { to_table: :spree_users, on_delete: :nullify }
      t.string :user_agent, limit: 512
      t.boolean :internal, null: false, default: false

      # This table is append-only, so an updated_at column would never change.
      t.datetime :created_at, null: false
    end

    add_index :api_logs, :created_at
  end
end
