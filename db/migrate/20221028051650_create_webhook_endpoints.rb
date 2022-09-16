# frozen_string_literal: true

class CreateWebhookEndpoints < ActiveRecord::Migration[6.1]
  def change
    create_table :webhook_endpoints do |t|
      t.string :url, null: false

      t.timestamps null: false
    end
  end
end
