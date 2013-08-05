
namespace :openfoodweb do

  namespace :dev do

    desc 'load sample data'
    task :load_sample_data => :environment do
      require File.expand_path('../../../spec/factories', __FILE__)
      require File.expand_path('../../../spec/support/spree/init', __FILE__)
      task_name = "openfoodweb:dev:load_sample_data"

      # -- Shipping / payment information
      unless Spree::Zone.find_by_name 'Australia'
        puts "[#{task_name}] Seeding shipping / payment information"
        zone = FactoryGirl.create(:zone, :name => 'Australia', :zone_members => [])
        country = Spree::Country.find_by_name('Australia')
        Spree::ZoneMember.create(:zone => zone, :zoneable => country)
        FactoryGirl.create(:shipping_method, :zone => zone)
        FactoryGirl.create(:payment_method, :environment => 'development')
      end


      # -- Taxonomies
      unless Spree::Taxonomy.find_by_name 'Products'
        puts "[#{task_name}] Seeding taxonomies"
        taxonomy = Spree::Taxonomy.find_by_name('Products') || FactoryGirl.create(:taxonomy, :name => 'Products')
        taxonomy_root = taxonomy.root

        ['Vegetables', 'Fruit', 'Oils', 'Preserves and Sauces', 'Dairy', 'Meat and Fish'].each do |taxon_name|
          FactoryGirl.create(:taxon, :name => taxon_name, :parent_id => taxonomy_root.id)
        end
      end

      # -- Enterprises
      unless Enterprise.count > 0
        puts "[#{task_name}] Seeding enterprises"

        3.times { FactoryGirl.create(:supplier_enterprise) }
        3.times { FactoryGirl.create(:distributor_enterprise) }
      end

      unless Spree::ShippingMethod.all.any? { |sm| sm.calculator.is_a? OpenFoodWeb::Calculator::Itemwise }
        FactoryGirl.create(:itemwise_shipping_method)
      end

      # -- Products
      unless Spree::Product.count > 0
        puts "[#{task_name}] Seeding products"

        prod1 = FactoryGirl.create(:product,
                           :name => 'Garlic', :price => 20.00,
                           :supplier => Enterprise.is_primary_producer[0],
                           :taxons => [Spree::Taxon.find_by_name('Vegetables')])

        ProductDistribution.create(:product => prod1,
                                   :distributor => Enterprise.is_distributor[0],
                                   :shipping_method => Spree::ShippingMethod.first)


        prod2 = FactoryGirl.create(:product,
                           :name => 'Fuji Apple', :price => 5.00,
                           :supplier => Enterprise.is_primary_producer[1],
                           :taxons => [Spree::Taxon.find_by_name('Fruit')])

        ProductDistribution.create(:product => prod2,
                                   :distributor => Enterprise.is_distributor[1],
                                   :shipping_method => Spree::ShippingMethod.first)

        prod3 = FactoryGirl.create(:product,
                           :name => 'Beef - 5kg Trays', :price => 50.00,
                           :supplier => Enterprise.is_primary_producer[2],
                           :taxons => [Spree::Taxon.find_by_name('Meat and Fish')])

        ProductDistribution.create(:product => prod3,
                                   :distributor => Enterprise.is_distributor[2],
                                   :shipping_method => Spree::ShippingMethod.first)
      end
    end
  end
end
