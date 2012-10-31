class CombineSuppliersAndDistributorsIntoEnterprises < ActiveRecord::Migration
  class Supplier < ActiveRecord::Base; end
  class Distributor < ActiveRecord::Base; end
  class Enterprise < ActiveRecord::Base; end
  class ProductDistribution < ActiveRecord::Base; end
  class Spree::Product < ActiveRecord::Base; end
  class Spree::Order < ActiveRecord::Base; end


  def up
    # Create enterprises table
    create_table :enterprises do |t|
      t.string   :name
      t.string   :description
      t.text     :long_description
      t.boolean  :is_primary_producer
      t.boolean  :is_distributor
      t.string   :contact
      t.string   :phone
      t.string   :email
      t.string   :website
      t.string   :twitter
      t.string   :abn
      t.string   :acn
      t.integer  :address_id
      t.string   :pickup_times
      t.integer  :pickup_address_id
      t.string   :next_collection_at
      t.timestamps
    end

    # Copy suppliers to enterprises table with primary producer flag set
    Supplier.all.each do |s|
      attrs = s.attributes
      attrs.reject! { |k| k == 'id' }
      attrs.merge! is_primary_producer: true, is_distributor: false
      e = Enterprise.create! attrs

      # Update supplier_id on product to point at the new enterprise
      Spree::Product.update_all("supplier_id=#{e.id}", "supplier_id=#{s.id}")
    end

    # Copy distributors to enterprises table with distributor flag set
    Distributor.all.each do |d|
      attrs = d.attributes
      attrs['website'] = attrs['url']
      attrs.reject! { |k| ['id', 'url'].include? k }
      attrs.merge! is_primary_producer: false, is_distributor: true
      e = Enterprise.create! attrs

      # Update distributor_id on product distribution and order to point at the new enterprise
      ProductDistribution.update_all("distributor_id=#{e.id}", "distributor_id=#{d.id}")
      Spree::Order.update_all("distributor_id=#{e.id}", "distributor_id=#{d.id}")
    end
  end

  def down
    drop_table :enterprises
  end
end
