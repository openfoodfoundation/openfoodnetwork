require 'faker'
require 'spree/core/testing_support/factories'

FactoryGirl.define do
  factory :enterprise, :class => Enterprise do
    sequence(:name) { |n| "Enterprise #{n}" }
    description 'enterprise'
    long_description '<p>Hello, world!</p><p>This is a paragraph.</p>'
    email 'enterprise@example.com'
    address { Spree::Address.first || FactoryGirl.create(:address) }
  end

  factory :supplier_enterprise, :parent => :enterprise do
    is_primary_producer true
    is_distributor false
  end

  factory :distributor_enterprise, :parent => :enterprise do
    is_primary_producer false
    is_distributor true
  end

  factory :enterprise_fee, :class => EnterpriseFee do
    enterprise { Enterprise.first || FactoryGirl.create(:supplier_enterprise) }
    fee_type 'packing'
    name '$0.50 / kg'
    calculator { FactoryGirl.build(:weight_calculator) }

    after_create { |ef| ef.calculator.save! }
  end

  factory :product_distribution, :class => ProductDistribution do
    product         { |pd| Spree::Product.first || FactoryGirl.create(:product) }
    distributor     { |pd| Enterprise.is_distributor.first || FactoryGirl.create(:distributor_enterprise) }
    shipping_method { |pd| Spree::ShippingMethod.where("name != 'Delivery'").first || FactoryGirl.create(:shipping_method) }
  end

  factory :itemwise_shipping_method, :parent => :shipping_method do
    name 'Delivery'
    calculator { FactoryGirl.build(:itemwise_calculator) }
  end

  factory :itemwise_calculator, :class => OpenFoodWeb::Calculator::Itemwise do
  end

  factory :weight_calculator, :class => OpenFoodWeb::Calculator::Weight do
    after_build  { |c| c.set_preference(:per_kg, 0.5) }
    after_create { |c| c.set_preference(:per_kg, 0.5); c.save! }
  end

end


FactoryGirl.modify do
  factory :simple_product do
    # Fix product factory name sequence with Kernel.rand so it is not interpreted as a Spree::Product method
    # Pull request: https://github.com/spree/spree/pull/1964
    # When this fix has been merged into a version of Spree that we're using, this line can be removed.
    sequence(:name) { |n| "Product ##{n} - #{Kernel.rand(9999)}" }

    supplier { Enterprise.is_primary_producer.first || FactoryGirl.create(:supplier_enterprise) }
    on_hand 3

    # before(:create) do |product, evaluator|
    #   product.product_distributions = [FactoryGirl.create(:product_distribution, :product => product)]
    # end

    # Do not create products distributed via the 'Delivery' shipping method
    after(:create) do |product, evaluator|
      pd = product.product_distributions.first
      if pd.andand.shipping_method.andand.name == 'Delivery'
        pd.shipping_method = Spree::ShippingMethod.where("name != 'Delivery'").first || FactoryGirl.create(:shipping_method)
        pd.save!
      end
    end
  end

  factory :line_item do
    shipping_method { |li| li.product.shipping_method_for_distributor(li.order.distributor) }
  end

  factory :shipping_method do
    display_on ''
  end

  factory :address do
    state { Spree::State.find_by_name 'Victoria' }
    country { Spree::Country.find_by_name 'Australia' || Spree::Country.first }
  end
end


# -- CMS
FactoryGirl.define do
  factory :cms_site, :class => Cms::Site do
    identifier 'open-food-web'
    label      'Open Food Web'
    hostname   'localhost'
  end

  factory :cms_layout, :class => Cms::Layout do
    site { Cms::Site.first || create(:cms_site) }
    label 'layout'
    identifier 'layout'
    content '{{ cms:page:content:text }}'
  end

  factory :cms_page, :class => Cms::Page do
    site { Cms::Site.first || create(:cms_site) }
    label 'page'
    sequence(:slug) { |n| "page-#{n}" }
    layout { Cms::Layout.first || create(:cms_layout) }

    # Pass content through to block, where it is stored
    after(:create) do |cms_page, evaluator|
      cms_page.blocks.first.update_attribute(:content, evaluator.content)
      cms_page.save! # set_cached_content
    end
  end

  factory :cms_block, :class => Cms::Block do
    page { Cms::Page.first || create(:cms_page) }
    identifier 'block'
    content 'hello, block'
  end
end
