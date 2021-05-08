# frozen_string_literal: true

require 'spec_helper'

feature '
    As an admin
    I want to check the unit price of my products/variants
' do
  include AuthenticationHelper
  include WebHelper
  
  let!(:stock_location) { create(:stock_location, backorderable_default: false) }
  
  before do
    allow(OpenFoodNetwork::FeatureToggle).to receive(:enabled?).with(:unit_price, anything) { true }
  end
  
  describe "product", js: true do
    scenario "creating a new product" do
      login_as_admin_and_visit spree.admin_products_path
      click_link 'New Product'
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in 'Value', with: '1'
      fill_in 'Price', with: '1'
      
      expect(find_field("Unit Price", disabled: true).value).to eq "$1.00 / kg"
    end
  end

  describe "variant", js: true do
    scenario "creating a new variant" do
      product = create(:simple_product, variant_unit: "weight", variant_unit_scale: "1")
      login_as_admin_and_visit spree.admin_product_variants_path product
      click_link 'New Variant'
      fill_in 'Weight (g)', with: '1'
      fill_in 'Price', with: '1'
      
      expect(find_field("Unit Price", disabled: true).value).to eq '$1,000.00 / kg'
    end

    scenario "editing a variant" do
      product = create(:simple_product, variant_unit: "weight", variant_unit_scale: "1")
      variant = product.variants.first
      variant.update(price: 1.0)
      login_as_admin_and_visit spree.edit_admin_product_variant_path(product, variant)
      
      expect(find_field("Unit Price", disabled: true).value).to eq '$1,000.00 / kg'
    end
  end
end
