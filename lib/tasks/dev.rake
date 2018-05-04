
namespace :openfoodnetwork do

  namespace :dev do

    desc 'load sample data'
    task load_sample_data: :environment do
      require_relative '../../spec/factories'
      require_relative '../../spec/support/spree/init'
      task_name = "openfoodnetwork:dev:load_sample_data"

      spree_user = Spree::User.find_by_email('spree@example.com')
      country = Spree::Country.find_by_iso(ENV.fetch('DEFAULT_COUNTRY_CODE'))
      state = country.states.first

      # -- Shipping / payment information
      unless Spree::Zone.find_by_name 'Australia'
        puts "[#{task_name}] Seeding shipping / payment information"

        zone = FactoryBot.create(:zone, name: 'Australia', zone_members: [])
        Spree::ZoneMember.create(zone: zone, zoneable: country)
        address = FactoryBot.create(
          :address,
          address1: "15/1 Ballantyne Street",
          zipcode: "3153",
          city: "Thornbury",
          country: country,
          state: state
        )
        enterprise = FactoryBot.create(:enterprise, address: address)

        FactoryBot.create(:shipping_method, zone: zone, distributors: [enterprise])
      end

      # -- Taxonomies
      unless Spree::Taxonomy.find_by_name 'Products'
        puts "[#{task_name}] Seeding taxonomies"
        taxonomy = Spree::Taxonomy.find_by_name('Products') || FactoryBot.create(:taxonomy, name: 'Products')
        taxonomy_root = taxonomy.root

        ['Vegetables', 'Fruit', 'Oils', 'Preserves and Sauces', 'Dairy', 'Meat and Fish'].each do |taxon_name|
          FactoryBot.create(:taxon, name: taxon_name, parent_id: taxonomy_root.id)
        end
      end

      # -- Addresses
      unless Spree::Address.find_by_zipcode "3160"
        puts "[#{task_name}] Seeding addresses"

        FactoryBot.create(:address, address1: "25 Myrtle Street", zipcode: "3153", city: "Bayswater", country: country, state: state)
        FactoryBot.create(:address, address1: "6 Rollings Road", zipcode: "3156", city: "Upper Ferntree Gully", country: country, state: state)
        FactoryBot.create(:address, address1: "72 Lake Road", zipcode: "3130", city: "Blackburn", country: country, state: state)
        FactoryBot.create(:address, address1: "7 Verbena Street", zipcode: "3195", city: "Mordialloc", country: country, state: state)
        FactoryBot.create(:address, address1: "20 Galvin Street", zipcode: "3018", city: "Altona", country: country, state: state)
        FactoryBot.create(:address, address1: "59 Websters Road", zipcode: "3106", city: "Templestowe", country: country, state: state)
        FactoryBot.create(:address, address1: "17 Torresdale Drive", zipcode: "3155", city: "Boronia", country: country, state: state)
        FactoryBot.create(:address, address1: "21 Robina CRT", zipcode: "3764", city: "Kilmore", country: country, state: state)
        FactoryBot.create(:address, address1: "25 Kendall Street", zipcode: "3134", city: "Ringwood", country: country, state: state)
        FactoryBot.create(:address, address1: "2 Mines Road", zipcode: "3135", city: "Ringwood East", country: country, state: state)
        FactoryBot.create(:address, address1: "183 Millers Road", zipcode: "3025", city: "Altona North", country: country, state: state)
        FactoryBot.create(:address, address1: "310 Pascoe Vale Road", zipcode: "3040", city: "Essendon", country: country, state: state)
        FactoryBot.create(:address, address1: "6 Martin Street", zipcode: "3160", city: "Belgrave", country: country, state: state)
      end

      # -- Enterprises
      unless Enterprise.count > 1
        puts "[#{task_name}] Seeding enterprises"

        3.times { FactoryBot.create(:supplier_enterprise, address: Spree::Address.find_by_zipcode("3160")) }

        FactoryBot.create(:distributor_enterprise, name: "Green Grass", address: Spree::Address.find_by_zipcode("3153"))
        FactoryBot.create(:distributor_enterprise, name: "AusFarmers United", address: Spree::Address.find_by_zipcode("3156"))
        FactoryBot.create(:distributor_enterprise, name: "Blackburn FreeGrossers", address: Spree::Address.find_by_zipcode("3130"))
        FactoryBot.create(:distributor_enterprise, name: "MegaFoods", address: Spree::Address.find_by_zipcode("3195"))
        FactoryBot.create(:distributor_enterprise, name: "Eco Butchers", address: Spree::Address.find_by_zipcode("3018"))
        FactoryBot.create(:distributor_enterprise, name: "Western Wines", address: Spree::Address.find_by_zipcode("3106"))
        FactoryBot.create(:distributor_enterprise, name: "QuickFresh", address: Spree::Address.find_by_zipcode("3155"))
        FactoryBot.create(:distributor_enterprise, name: "Fooderers", address: Spree::Address.find_by_zipcode("3764"))
        FactoryBot.create(:distributor_enterprise, name: "Food Local", address: Spree::Address.find_by_zipcode("3134"))
        FactoryBot.create(:distributor_enterprise, name: "Green Food Trading Corporation", address: Spree::Address.find_by_zipcode("3135"))
        FactoryBot.create(:distributor_enterprise, name: "Better Food", address: Spree::Address.find_by_zipcode("3025"))
        FactoryBot.create(:distributor_enterprise, name: "Gippsland Poultry", address: Spree::Address.find_by_zipcode("3040"))
      end

      # -- Enterprise users
      unless Spree::User.count > 1
        puts "[#{task_name}] Seeding enterprise users"

        pw = "spree123"

        u = FactoryBot.create(:user, email: "sup@example.com", password: pw, password_confirmation: pw)
        u.enterprises << Enterprise.is_primary_producer.first
        u.enterprises << Enterprise.is_primary_producer.second
        puts "  Supplier User created:    #{u.email}/#{pw}  (" + u.enterprise_roles.map{ |er| er.enterprise.name}.join(", ") + ")"

        u = FactoryBot.create(:user, email: "dist@example.com", password: pw, password_confirmation: pw)
        u.enterprises << Enterprise.is_distributor.first
        u.enterprises << Enterprise.is_distributor.second
        puts "  Distributor User created: #{u.email}/#{pw} (" + u.enterprise_roles.map{ |er| er.enterprise.name}.join(", ") + ")"
      end

      # -- Enterprise fees
      unless EnterpriseFee.count > 1
        Enterprise.is_distributor.each do |distributor|
          FactoryBot.create(:enterprise_fee, enterprise: distributor)
        end
      end

      # -- Enterprise Payment Methods
      unless Spree::PaymentMethod.count > 1
        Enterprise.is_distributor.each do |distributor|
          FactoryBot.create(:payment_method, distributors: [distributor], name: "Cheque (#{distributor.name})", environment: 'development')
        end
      end

      # -- Products
      unless Spree::Product.count > 0
        puts "[#{task_name}] Seeding products"

        prod1 = FactoryBot.create(:product,
                           name: 'Garlic', price: 20.00,
                           supplier: Enterprise.is_primary_producer[0],
                           taxons: [Spree::Taxon.find_by_name('Vegetables')])

        ProductDistribution.create(product: prod1,
                                   distributor: Enterprise.is_distributor[0],
                                   enterprise_fee: Enterprise.is_distributor[0].enterprise_fees.first)


        prod2 = FactoryBot.create(:product,
                           name: 'Fuji Apple', price: 5.00,
                           supplier: Enterprise.is_primary_producer[1],
                           taxons: [Spree::Taxon.find_by_name('Fruit')])

        ProductDistribution.create(product: prod2,
                                   distributor: Enterprise.is_distributor[1],
                                   enterprise_fee: Enterprise.is_distributor[1].enterprise_fees.first)

        prod3 = FactoryBot.create(:product,
                           name: 'Beef - 5kg Trays', price: 50.00,
                           supplier: Enterprise.is_primary_producer[2],
                           taxons: [Spree::Taxon.find_by_name('Meat and Fish')])

        ProductDistribution.create(product: prod3,
                                   distributor: Enterprise.is_distributor[2],
                                   enterprise_fee: Enterprise.is_distributor[2].enterprise_fees.first)

        prod4 = FactoryBot.create(:product,
                                   name: 'Carrots', price: 3.00,
                                   supplier: Enterprise.is_primary_producer[2],
                                   taxons: [Spree::Taxon.find_by_name('Meat and Fish')])

        ProductDistribution.create(product: prod4,
                                   distributor: Enterprise.is_distributor[2],
                                   enterprise_fee: Enterprise.is_distributor[2].enterprise_fees.first)

        prod5 = FactoryBot.create(:product,
                                   name: 'Potatoes', price: 2.00,
                                   supplier: Enterprise.is_primary_producer[2],
                                   taxons: [Spree::Taxon.find_by_name('Meat and Fish')])

        ProductDistribution.create(product: prod5,
                                   distributor: Enterprise.is_distributor[2],
                                   enterprise_fee: Enterprise.is_distributor[2].enterprise_fees.first)

        prod6 = FactoryBot.create(:product,
                                   name: 'Tomatoes', price: 2.00,
                                   supplier: Enterprise.is_primary_producer[2],
                                   taxons: [Spree::Taxon.find_by_name('Meat and Fish')])

        ProductDistribution.create(product: prod6,
                                   distributor: Enterprise.is_distributor[2],
                                   enterprise_fee: Enterprise.is_distributor[2].enterprise_fees.first)

        prod7 = FactoryBot.create(:product,
                                   name: 'Potatoes', price: 2.00,
                                   supplier: Enterprise.is_primary_producer[2],
                                   taxons: [Spree::Taxon.find_by_name('Meat and Fish')])

        ProductDistribution.create(product: prod7,
                                   distributor: Enterprise.is_distributor[2],
                                   enterprise_fee: Enterprise.is_distributor[2].enterprise_fees.first)

      end

      enterprise2 = Enterprise.find_by_name('Enterprise 2')
      enterprise2.sells = 'any'
      enterprise2.shipping_methods.build(
        name: 'Pickup',
        zone_id: 3,
        require_ship_address: true,
        calculator_type: 'OpenFoodNetwork::Calculator::Weight',
        distributor_ids: [enterprise2.id]
      )
      enterprise2.payment_methods << Spree::PaymentMethod.last
      enterprise2.save!

      variants = Spree::Variant
        .joins(:product)
        .where('spree_products.supplier_id = ?', enterprise2.id)

      CreateOrderCycle.new(enterprise2, variants).call

      EnterpriseRole.create!(user: Spree::User.first, enterprise: enterprise2)

      spree_user.confirm!
    end
  end
end
