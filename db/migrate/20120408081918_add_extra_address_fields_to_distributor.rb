class AddExtraAddressFieldsToDistributor < ActiveRecord::Migration
  def change
    add_column :distributors, :city, :string
    add_column :distributors, :post_code, :string
    add_column :distributors, :country_id, :integer
  end
end
