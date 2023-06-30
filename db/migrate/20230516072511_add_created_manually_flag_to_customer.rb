# frozen_string_literal: true

class AddCreatedManuallyFlagToCustomer < ActiveRecord::Migration[7.0]
  def change
    add_column :customers, :created_manually, :boolean, null: false, default: false
    add_index :customers, :created_manually
  end
end
