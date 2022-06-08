# frozen_string_literal: true

class AddLandmarkToAddress < ActiveRecord::Migration[6.1]
  def change
    add_column :spree_addresses, :landmark, :string, limit: 255
  end
end
