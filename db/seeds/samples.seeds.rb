
require 'yaml'

require File.expand_path('../../../spec/factories', __FILE__)
require File.expand_path('../../../spec/support/spree/init', __FILE__)


# -- Addresses
sample_data = YAML::load_file File.join ['db', 'seeds', OpenFoodNetwork::Config.country_code.downcase, 'sample_data.yml']
unless Spree::Address.find_by_zipcode sample_data['addresses'][0]['zipcode']
  puts "[db:seed] Seeding addresses"
  Spree::Address.delete_all

  sample_data['addresses'].each do |address|
    FactoryGirl.create(:address, :address1 => address['address1'], :zipcode => address['zipcode'], :city => address['city'])
  end
end

# -- Enterprises
unless Enterprise.count > 1
  puts "[db:seed] Seeding enterprises"

  3.times { FactoryGirl.create(:supplier_enterprise, :address => Spree::Address.find_by_zipcode(sample_data['addresses'][0]['zipcode'])) }

  sample_data['enterprises'].each do |enterprise|
    FactoryGirl.create(:distributor_enterprise, :name => enterprise['name'], :address => Spree::Address.find_by_zipcode(enterprise['address']))
  end
end

# -- Enterprise users
unless Spree::User.count > 1
  puts "[db:seed] Seeding enterprise users"

  pw = "spree123"

  u = FactoryGirl.create(:user, email: sample_data['users'][0]['email'], password: pw, password_confirmation: pw)
  u.enterprises << Enterprise.is_primary_producer.first
  u.enterprises << Enterprise.is_primary_producer.second
  puts "  Supplier User created:    #{u.email}/#{pw}  (" + u.enterprise_roles.map{ |er| er.enterprise.name}.join(", ") + ")"

  u = FactoryGirl.create(:user, email: sample_data['users'][1]['email'], password: pw, password_confirmation: pw)
  u.enterprises << Enterprise.is_distributor.first
  u.enterprises << Enterprise.is_distributor.second
  puts "  Distributor User created: #{u.email}/#{pw} (" + u.enterprise_roles.map{ |er| er.enterprise.name}.join(", ") + ")"
end

# -- Enterprise fees
unless EnterpriseFee.count > 1
  puts "[db:seed] Seeding enterprise fees"
  Enterprise.is_distributor.each do |distributor|
    FactoryGirl.create(:enterprise_fee, enterprise: distributor)
  end
end

# -- Enterprise Payment Methods
unless Spree::PaymentMethod.count > 1
  puts "[db:seed] Seeding payment methods"
  Enterprise.is_distributor.each do |distributor|
    FactoryGirl.create(:payment_method, distributors: [distributor], name: "Cheque (#{distributor.name})", :environment => 'development')
  end
end

# -- Products
unless Spree::Product.count > 0
  puts "[db:seed] Seeding products"

  sample_data['products'].each do |product|
    prod1 = FactoryGirl.create(:product,
                       :name => product['name'], :price => 20.00,
                       :supplier => Enterprise.is_primary_producer[0],
                       :taxons => [Spree::Taxon.find_by_name(product['category'])])

    ProductDistribution.create(:product => prod1,
                               :distributor => Enterprise.is_distributor[0],
                               :enterprise_fee => Enterprise.is_distributor[0].enterprise_fees.first)
  end
end

