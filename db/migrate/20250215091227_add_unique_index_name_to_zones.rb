# frozen_string_literal: true

class AddUniqueIndexNameToZones < ActiveRecord::Migration[7.0]
  def change
    add_index(:spree_zones, :name, unique: true)
  end
end
