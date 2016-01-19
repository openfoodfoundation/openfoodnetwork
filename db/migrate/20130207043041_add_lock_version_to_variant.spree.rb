# This migration comes from spree (originally 20121009142519)
class AddLockVersionToVariant < ActiveRecord::Migration
  def change
    add_column :spree_variants, :lock_version, :integer, default: 0
  end
end
