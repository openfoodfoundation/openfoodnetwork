class AddDfcNameToSpreeTaxons < ActiveRecord::Migration[7.0]
  def change
    add_column :spree_taxons, :dfc_name, :string
  end
end
