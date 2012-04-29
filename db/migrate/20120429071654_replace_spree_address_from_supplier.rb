class ReplaceSpreeAddressFromSupplier < ActiveRecord::Migration
  def change
      remove_column :suppliers, :address_id
      remove_column :suppliers, :url

      add_column :suppliers, :address, :string
      add_column :suppliers, :city, :string
      add_column :suppliers, :postcode, :string
      add_column :suppliers, :state_id, :integer
      add_column :suppliers, :country_id, :integer
  end
end
