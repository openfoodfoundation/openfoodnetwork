# frozen_string_literal: true

FactoryBot.define do
  factory :enterprise, class: Enterprise do
    transient do
      users { [] }
      logo {}
      promo_image {}
    end

    owner factory: :user
    sequence(:name) { |n| "Enterprise #{n}" }
    sells { 'any' }
    description { 'enterprise' }
    long_description { '<p>Hello, world!</p><p>This is a paragraph.</p>' }
    address
    visible { 'public' }

    after(:create) do |enterprise, proxy|
      proxy.users.each do |user|
        enterprise.users << user unless enterprise.users.include?(user)
      end
      enterprise.update logo: proxy.logo, promo_image: proxy.promo_image
    end
  end

  trait :with_logo_image do
    logo { Rack::Test::UploadedFile.new('spec/fixtures/files/logo.png', 'image/png') }
  end

  trait :with_promo_image do
    logo { Rack::Test::UploadedFile.new('spec/fixtures/files/promo.png', 'image/png') }
  end

  factory :supplier_enterprise, parent: :enterprise do
    is_primary_producer { true }
    sells { "none" }
  end

  factory :supplier_enterprise_hidden, parent: :enterprise do
    is_primary_producer { true }
    sells { "none" }
    visible { "hidden" }
  end

  factory :distributor_enterprise, parent: :enterprise do
    is_primary_producer { false }
    sells { "any" }

    transient do
      with_payment_and_shipping { false }
    end

    after(:create) do |enterprise, proxy|
      if proxy.with_payment_and_shipping
        create(:payment_method,  distributors: [enterprise])
        create(:shipping_method, distributors: [enterprise])
      end
    end
  end

  factory :distributor_enterprise_with_tax, parent: :distributor_enterprise do
    charges_sales_tax { true }
    allow_order_changes { true }
    abn { "222333444" }
    acn { "555666777" }
  end
end
