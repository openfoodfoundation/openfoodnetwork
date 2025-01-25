# frozen_string_literal: true

class CustomersCreatedManuallyRemoveNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :customers, :created_manually, true
  end
end
