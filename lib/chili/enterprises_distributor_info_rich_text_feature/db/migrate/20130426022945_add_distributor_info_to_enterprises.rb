class AddDistributorInfoToEnterprises < ActiveRecord::Migration
  def change
    add_column :enterprises, :distributor_info, :text
  end
end
