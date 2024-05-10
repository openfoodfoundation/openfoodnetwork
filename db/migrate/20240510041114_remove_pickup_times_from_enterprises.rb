# frozen_string_literal: true

class RemovePickupTimesFromEnterprises < ActiveRecord::Migration[7.0]
  def change
    remove_column :enterprises, :pickup_times, :text
  end
end
