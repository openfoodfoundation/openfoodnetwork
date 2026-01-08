# frozen_string_literal: true

class AddTypeToWebhookEndpoints < ActiveRecord::Migration[7.1]
  def up
    # Using "order_cycle_opened" as default will update existing record
    change_table(:webhook_endpoints, bulk: true) do |t|
      t.column :webhook_type, :string, limit: 255, null: false, default: "order_cycle_opened"
    end
    # Drop the default value
    change_column_default :webhook_endpoints, :webhook_type, nil
  end

  def down
    remove_column :webhook_endpoints, :webhook_type
  end
end
