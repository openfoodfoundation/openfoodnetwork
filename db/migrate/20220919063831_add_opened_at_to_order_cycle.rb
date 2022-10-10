# frozen_string_literal: true

class AddOpenedAtToOrderCycle < ActiveRecord::Migration[6.1]
  def change
    add_column :order_cycles, :opened_at, :timestamp
  end
end
