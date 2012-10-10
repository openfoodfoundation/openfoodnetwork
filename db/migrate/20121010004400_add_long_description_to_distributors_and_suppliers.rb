class AddLongDescriptionToDistributorsAndSuppliers < ActiveRecord::Migration
  def change
    add_column :distributors, :long_description, :text
    add_column :suppliers,    :long_description, :text
  end
end
