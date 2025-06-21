# frozen_string_literal: true

class AddUniqueIndexNameAndDeletedAtToTaxCategories < ActiveRecord::Migration[7.0]
  def change
    add_index(:spree_tax_categories, [:name, :deleted_at], unique: true)
  end
end
