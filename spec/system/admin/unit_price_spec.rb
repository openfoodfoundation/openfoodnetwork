# frozen_string_literal: true

require 'system_helper'

RSpec.describe '
    As an admin
    I want to check the unit price of my products/variants
' do
  include AuthenticationHelper
  include WebHelper

  describe "product" do
    it "creating a new product" do
      login_as_admin
      visit spree.admin_products_path
      click_link 'New Product'
      select "Weight (kg)", from: 'product_variant_unit_with_scale'
      fill_in 'Value', with: '1'
      fill_in 'Price', with: '1'

      expect(find_field("Unit Price", disabled: true).value).to eq "$1.00 / kg"
    end
  end

  describe "variant" do
    it "creating a new variant" do
      product = create(:simple_product, variant_unit: "weight", variant_unit_scale: "1")
      login_as_admin
      visit spree.admin_product_variants_path product
      click_link 'New Variant'

      tomselect_select "Weight (g)", from: "Unit scale"
      click_on "Unit" # activate popout
      fill_in "Unit value", with: "1"
      fill_in 'Price', with: '1'

      expect(find_field("Unit Price", disabled: true).value).to eq '$1,000.00 / kg'
    end

    it "editing a variant" do
      product = create(:simple_product, variant_unit: "weight", variant_unit_scale: "1")
      variant = product.variants.first
      variant.update(price: 1.0)
      login_as_admin
      visit spree.edit_admin_product_variant_path(product, variant)

      expect(find_field("Unit Price", disabled: true).value).to eq '$1,000.00 / kg'
    end
  end

  describe "when admin use es as default language (and comma as decimal separator)" do
    it "creating a new product with a comma separated decimal price" do
      login_as_admin
      visit spree.admin_dashboard_path(locale: 'es')
      visit spree.admin_products_path
      click_link 'Nuevo producto'
      select "Peso (kg)", from: 'product_variant_unit_with_scale'
      fill_in 'Valor', with: '1'
      fill_in 'Precio', with: '1,5'

      expect(find_field("Precio por unidad", disabled: true).value).to eq "1,50 $ / kg"
    end

    it "creating a new variant with a comma separated decimal price" do
      product = create(:simple_product, variant_unit: "weight", variant_unit_scale: "1")
      login_as_admin

      visit spree.admin_dashboard_path(locale: 'es')
      visit spree.admin_product_variants_path product
      click_link 'Nueva Variante'

      tomselect_select "Peso (g)", from: "Escala de unidades"
      click_on "Unidad" # activate popout
      fill_in "Valor unidad", with: "1"
      fill_in 'Precio', with: '1,5'

      expect(find_field("Precio por unidad", disabled: true).value).to eq '1.500,00 $ / kg'
    end

    it "editing a variant with a comma separated decimal price" do
      product = create(:simple_product, variant_unit: "weight", variant_unit_scale: "1")
      variant = product.variants.first
      variant.update(price: 1.5)
      login_as_admin
      visit spree.admin_dashboard_path(locale: 'es')
      visit spree.edit_admin_product_variant_path(product, variant)

      expect(find_field("Precio por unidad", disabled: true).value).to eq '1.500,00 $ / kg'
    end
  end
end
