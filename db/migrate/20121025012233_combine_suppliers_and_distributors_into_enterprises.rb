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
    updated_product_ids = [-1]
    Supplier.all.each do |s|
      attrs = s.attributes
      attrs.reject! { |k| k == 'id' }
      attrs.merge! is_primary_producer: true, is_distributor: false
      e = Enterprise.create! attrs

      # Update supplier_id on product to point at the new enterprise
      product_ids = Spree::Product.where(:supplier_id => s.id).pluck(:id)
      Spree::Product.update_all("supplier_id=#{e.id}", "supplier_id=#{s.id} AND id NOT IN (#{updated_product_ids.join(', ')})")
      updated_product_ids += product_ids
    end

    # Copy distributors to enterprises table with distributor flag set
    updated_product_distribution_ids = [-1]
    updated_order_ids = [-1]
    Distributor.all.each do |d|
      attrs = d.attributes
      attrs['website'] = attrs['url']
      attrs.reject! { |k| ['id', 'url'].include? k }
      attrs.merge! is_primary_producer: false, is_distributor: true
      e = Enterprise.create! attrs

      # Update distributor_id on product distribution and order to point at the new enterprise
      product_distribution_ids = ProductDistribution.where(:distributor_id => d.id).pluck(:id)
      order_ids = Spree::Order.where(:distributor_id => d.id).pluck(:id)
      ProductDistribution.update_all("distributor_id=#{e.id}", "distributor_id=#{d.id} AND id NOT IN (#{updated_product_distribution_ids.join(', ')})")
      Spree::Order.update_all("distributor_id=#{e.id}", "distributor_id=#{d.id} AND id NOT IN (#{updated_order_ids.join(', ')})")
      updated_product_distribution_ids += product_distribution_ids
      updated_order_ids += order_ids
    end
  end

  def down
    drop_table :enterprises
  end
end
