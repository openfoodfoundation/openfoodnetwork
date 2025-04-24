# frozen_string_literal: true

class AddEnableProducersToEditOrdersToEnterprises < ActiveRecord::Migration[7.0]
  def change
    add_column :enterprises, :enable_producers_to_edit_orders, :boolean, default: false, null: false
  end
end
