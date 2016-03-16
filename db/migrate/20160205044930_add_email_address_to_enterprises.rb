class AddEmailAddressToEnterprises < ActiveRecord::Migration
  def change
    add_column :enterprises, :email_address, :string
  end
end
