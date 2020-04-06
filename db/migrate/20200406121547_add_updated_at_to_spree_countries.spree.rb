# This migration comes from spree (originally 20130618041418)
class AddUpdatedAtToSpreeCountries < ActiveRecord::Migration
  def up
    add_column :spree_countries, :updated_at, :datetime
  end

  def down
    remove_column :spree_countries, :updated_at
  end
end
