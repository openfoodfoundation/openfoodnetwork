class RemoveIconFromSpreeTaxons < ActiveRecord::Migration[6.1]
  def change
    remove_column :spree_taxons, :icon_file_name, :string
    remove_column :spree_taxons, :icon_content_type, :string
    remove_column :spree_taxons, :icon_file_size, :integer
    remove_column :spree_taxons, :icon_updated_at, :datetime
  end
end
