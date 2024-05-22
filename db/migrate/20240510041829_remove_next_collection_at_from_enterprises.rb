# frozen_string_literal: true

class RemoveNextCollectionAtFromEnterprises < ActiveRecord::Migration[7.0]
  def change
    remove_column :enterprises, :next_collection_at, :string
  end
end
