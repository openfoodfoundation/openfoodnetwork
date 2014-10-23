class AddProducerProfileOnlyToEnterprises < ActiveRecord::Migration
  def change
    add_column :enterprises, :producer_profile_only, :boolean, default: false
  end
end
