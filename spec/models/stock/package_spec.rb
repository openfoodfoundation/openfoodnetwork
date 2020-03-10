require 'spec_helper'

module Stock
  describe Package do
    let(:stock_location) { double(:stock_location) }

    subject(:package) { Package.new(stock_location, order, contents) }

    let(:enterprise) { create(:enterprise) }
    let(:other_enterprise) { create(:enterprise) }

    let(:order) { build(:order, distributor: enterprise) }

    let(:variant1) do
      instance_double(
        Spree::Variant,
        shipping_category: shipping_method1.shipping_categories.first
      )
    end
    let(:variant2) do
      instance_double(
        Spree::Variant,
        shipping_category: shipping_method2.shipping_categories.first
      )
    end
    let(:variant3) do
      instance_double(Spree::Variant, shipping_category: nil)
    end

    let(:contents) do
      [
        Package::ContentItem.new(variant1, 1),
        Package::ContentItem.new(variant1, 1),
        Package::ContentItem.new(variant2, 1),
        Package::ContentItem.new(variant3, 1)
      ]
    end

    let(:shipping_method1) { create(:shipping_method, distributors: [enterprise]) }
    let(:shipping_method2) { create(:shipping_method, distributors: [other_enterprise]) }

    describe '#shipping_methods' do
      it 'does not return shipping methods not used by the package\'s order distributor' do
        expect(package.shipping_methods).to eq [shipping_method1]
      end
    end

    describe '#shipping_categories' do
      it "returns shipping categories that are not shipping categories of the order's products" do
        package
        other_shipping_category = Spree::ShippingCategory.create(name: "Custom")

        expect(package.shipping_categories).to eq [shipping_method1.shipping_categories.first,
                                                   other_shipping_category]
      end
    end
  end
end
