class RemovePickupAddressFromEnterprises < ActiveRecord::Migration
  class Enterprise < ActiveRecord::Base; end

  def up
    Enterprise.all.each do |e|
      e.address_id ||= e.pickup_address_id
      e.save!
    end

    remove_column :enterprises, :pickup_address_id
  end

  def down
    add_column :enterprises, :pickup_address_id, :integer

    Enterprise.all.each do |e|
      e.pickup_address_id ||= e.address_id
      e.save!
    end
  end
end
