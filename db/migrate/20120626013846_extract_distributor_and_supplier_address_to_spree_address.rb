class ExtractDistributorAndSupplierAddressToSpreeAddress < ActiveRecord::Migration
  class Supplier < ActiveRecord::Base; end
  class Distributor < ActiveRecord::Base; end
  class Spree::Address < ActiveRecord::Base; end


  def up
    # -- Distributors
    add_column :distributors, :pickup_address_id, :integer
    Distributor.reset_column_information

    Distributor.all.each do |distributor|
      pickup_address = Spree::Address.create!(:firstname => 'unused',
                                              :lastname => 'unused',
                                              :phone => 'unused',
                                              :address1 => distributor[:pickup_address],
                                              :city => distributor.city,
                                              :zipcode => distributor.post_code,
                                              :state_id => distributor.state_id,
                                              :country_id => distributor.country_id)
      distributor.pickup_address = pickup_address
      distributor.save!
    end

    %w(pickup_address city post_code state_id country_id).each do |column|
      remove_column :distributors, column
    end


    # -- Suppliers
    add_column :suppliers, :address_id, :integer
    Supplier.reset_column_information

    Supplier.all.each do |supplier|
      address = Spree::Address.create!(:firstname => 'unused',
                                       :lastname => 'unused',
                                       :phone => 'unused',
                                       :address1 => supplier[:address],
                                       :city => supplier.city,
                                       :zipcode => supplier.postcode,
                                       :state_id => supplier.state_id,
                                       :country_id => supplier.country_id)
      supplier.address = address
      supplier.save!
    end

    %w(address city postcode state_id country_id).each do |column|
      remove_column :suppliers, column
    end
  end

  def down
    # -- Distributors
    add_column :distributors, :pickup_address, :string
    add_column :distributors, :city, :string
    add_column :distributors, :post_code, :string
    add_column :distributors, :state_id, :integer
    add_column :distributors, :country_id, :integer
    Distributor.reset_column_information

    Distributor.all.each do |distributor|
      distributor[:pickup_address] = distributor.pickup_address.address1
      distributor.city = distributor.pickup_address.city
      distributor.post_code = distributor.pickup_address.zipcode
      distributor.state_id = distributor.pickup_address.state_id
      distributor.country_id = distributor.pickup_address.country_id
      distributor.save!
    end

    remove_column :distributors, :pickup_address_id


    # -- Suppliers
    add_column :suppliers, :address, :string
    add_column :suppliers, :city, :string
    add_column :suppliers, :postcode, :string
    add_column :suppliers, :state_id, :integer
    add_column :suppliers, :country_id, :integer
    Supplier.reset_column_information

    Supplier.all.each do |supplier|
      supplier[:address] = supplier.address.address1
      supplier.city = supplier.address.city
      supplier.post_code = supplier.address.zipcode
      supplier.state_id = supplier.address.state_id
      supplier.country_id = supplier.address.country_id
      supplier.save!
    end

    remove_column :suppliers, :address_id
  end
end
