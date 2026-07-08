# frozen_string_literal: true

class AddDeletedAtToAssets < ActiveRecord::Migration[7.1]
  def change
    add_column :spree_assets, :deleted_at, :datetime
    add_index :spree_assets, :deleted_at
  end
end
