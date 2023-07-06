class VariantTimestamps < ActiveRecord::Migration[7.0]
  def change
    add_timestamps :spree_variants, null: false, default: -> { "NOW()" }
  end
end
