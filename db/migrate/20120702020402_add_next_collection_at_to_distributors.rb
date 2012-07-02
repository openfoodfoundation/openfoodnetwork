class AddNextCollectionAtToDistributors < ActiveRecord::Migration
  def change
    add_column :distributors, :next_collection_at, :string
  end
end
