# frozen_string_literal: true

require 'system_helper'

describe '
    As an admin
    I want to manage product variants
' do
  include AuthenticationHelper
  include WebHelper

  describe "new variant" do
    it "creating a new variant" do
      # Given a product with a unit-related option type
      product = create(:simple_product, variant_unit: "weight", variant_unit_scale: "1")

      # When I create a variant on the product
      login_as_admin
      visit spree.admin_product_variants_path product
      click_link 'New Variant'

      fill_in 'unit_value_human', with: '1'
      fill_in 'variant_unit_description', with: 'foo'
      click_button 'Create'

      # Then the variant should have been created
      expect(page).to have_content "Variant \"#{product.name}\" has been successfully created!"
    end

    it "creating a new variant from product variant page with filter" do
      # Given a product with a unit-related option type
      product = create(:simple_product, variant_unit: "weight", variant_unit_scale: "1")
      filter = { producerFilter: 2 }

      # When I create a variant on the product
      login_as_admin
      visit spree.admin_product_variants_path(product, filter)

      click_link 'New Variant'

      uri = URI.parse(current_url)
      expect("#{uri.path}?#{uri.query}").to eq spree.new_admin_product_variant_path(product, filter)

      # Cancel link should include product filter
      expected_cancel_url = Regexp.new(
        Regexp.escape(spree.admin_product_variants_path(product, filter))
      )
      expect(page).to have_link('Cancel', href: expected_cancel_url)
    end

    it "creating a new variant with non-weight unit type" do
      # Given a product with a unit-related option type
      product = create(:simple_product, variant_unit: "volume", variant_unit_scale: "1")

      # When I create a variant on the product
      login_as_admin
      visit spree.admin_product_variants_path product

      click_link 'New Variant'

      # Expect variant_weight to accept 3 decimal places
      fill_in 'variant_weight', with: '1.234'
      fill_in 'unit_value_human', with: 1
      click_button 'Create'

      # Then the variant should have been created
      expect(page).to have_content "Variant \"#{product.name}\" has been successfully created!"
    end

    it "show validation errors if present" do
      product = create(:simple_product, variant_unit: "volume", variant_unit_scale: "1")
      login_as_admin
      visit spree.admin_product_variants_path product
      click_link 'New Variant'

      fill_in 'unit_value_human', with: 0
      click_button 'Create'

      expect(page).to have_content "Unit value must be greater than 0"
    end
  end

  describe "viewing product variant" do
    it "when the product page has a product filter" do
      # Given a product with a unit-related option type
      product = create(:simple_product, variant_unit: "weight", variant_unit_scale: "1")
      filter = { producerFilter: 2 }

      # When I create a variant on the product
      login_as_admin
      visit spree.admin_product_variants_path(product, filter)

      expected_new_url = Regexp.new(
        Regexp.escape(spree.new_admin_product_variant_path(product, filter))
      )
      expect(page).to have_link("New Variant", href: expected_new_url)

      expected_show_delete_url = Regexp.new(
        Regexp.escape(spree.admin_product_variants_path(product, { deleted: 'on' }.merge(filter)))
      )
      expect(page).to have_link("Show Deleted", href: expected_show_delete_url)

      # Variant link should include product filter
      variant = product.variants.first

      expected_edit_url = Regexp.new(
        Regexp.escape(spree.edit_admin_product_variant_path(product, variant, filter))
      )
      expect(page).to have_link(class: 'icon-edit', href: expected_edit_url)

      expected_delete_url = Regexp.new(
        Regexp.escape(spree.admin_product_variant_path(product, variant, filter))
      )
      expect(page).to have_link(class: 'icon-trash', href: expected_delete_url)
    end
  end

  describe "editing unit value and description for a variant" do
    it "when the product variant page has product filter" do
      product = create(:simple_product, variant_unit: "weight", variant_unit_scale: "1")
      filter = { producerFilter: 2 }

      # When I create a variant on the product
      login_as_admin
      visit spree.admin_product_variants_path(product, filter)
      page.find('table.index .icon-edit').click

      # Cancel link should include product filter
      expected_cancel_url = Regexp.new(
        Regexp.escape(spree.admin_product_variants_path(product, filter))
      )
      expect(page).to have_link('Cancel', href: expected_cancel_url)
    end

    it "when variant_unit is weight" do
      # Given a product with unit-related option types, with a variant
      product = create(:simple_product, variant_unit: "weight", variant_unit_scale: "1")
      variant = product.variants.first
      variant.update( unit_value: 1, unit_description: 'foo' )

      # When I view the variant
      login_as_admin
      visit spree.admin_product_variants_path product

      page.find('table.index .icon-edit').click

      # And I should see unit value and description fields for the unit-related option value
      expect(page).to have_field "unit_value_human", with: "1"
      expect(page).to have_field "variant_unit_description", with: "foo"

      # When I update the fields and save the variant
      fill_in "unit_value_human", with: "123"
      fill_in "variant_unit_description", with: "bar"
      click_button 'Update'
      expect(page).to have_content %(Variant "#{product.name}" has been successfully updated!)

      # Then the unit value and description should have been saved
      expect(variant.reload.unit_value).to eq(123)
      expect(variant.unit_description).to eq('bar')
    end

    it "can update unit_description when variant_unit is items" do
      product = create(:simple_product, variant_unit: "items", variant_unit_name: "bunches")
      variant = product.variants.first
      variant.update(unit_description: 'foo')

      login_as_admin
      visit spree.edit_admin_product_variant_path(product, variant)

      expect(page).to_not have_field "unit_value_human"
      expect(page).to have_field "variant_weight"
      expect(page).to have_field "variant_unit_description", with: "foo"

      fill_in "variant_unit_description", with: "bar"
      fill_in "variant_weight", with: "1.234"
      click_button 'Update'
      expect(page).to have_content %(Variant "#{product.name}" has been successfully updated!)
      expect(variant.reload.unit_description).to eq('bar')
    end

    context "with ES as a locale" do
      let(:product) { create(:simple_product, variant_unit: "weight", variant_unit_scale: "1") }
      let(:variant) { product.variants.first }

      around do |example|
        I18n.default_locale = :es
        example.run
        I18n.default_locale = :en
      end

      before do
        variant.update( unit_value: 1, unit_description: 'foo' )

        # When I view the variant
        login_as_admin
        visit spree.admin_product_variants_path product
      end

      shared_examples "with localization" do |localized, decimal_mark, thousands_separator|
        context "set to #{localized}" do
          before do
            allow(Spree::Config).to receive(:enable_localized_number?).and_return localized
            Spree::Config[:currency_decimal_mark] = decimal_mark
            Spree::Config[:currency_thousands_separator] = thousands_separator
          end

          it "when variant_unit is weight" do
            expect(variant.price).to eq(19.99)

            # Given a product with unit-related option types, with a variant
            page.find('table.index .icon-edit').click

            # assert on the price field
            expect(page).to have_field "variant_price", with: "19,99"

            # When I update the fields and save the variant
            fill_in "variant_price", with: "12,50"
            click_button 'Actualizar'
            expect(page).to have_content \
              %(Variant "#{product.name}" ha sido actualizado exitosamente)

            # Then the variant price should have been updated
            expect(variant.reload.price).to eq(12.50)
          end
        end
      end

      it_behaves_like "with localization", false, ".", ","
      it_behaves_like "with localization", true, ".", ","
      it_behaves_like "with localization", false, ",", "."
      it_behaves_like "with localization", true, ",", "."
    end
  end

  describe "editing on hand and on demand values" do
    let(:product) { create(:simple_product) }
    let(:variant) { product.variants.first }

    before do
      login_to_admin_section
    end

    it "allows changing the on_hand value" do
      visit spree.edit_admin_product_variant_path(product, variant)

      expect(page).to have_field "variant_on_hand", with: variant.on_hand
      expect(page).to have_unchecked_field "variant_on_demand"

      fill_in "variant_on_hand", with: "123"
      click_button 'Update'
      expect(page).to have_content %(Variant "#{product.name}" has been successfully updated!)
    end

    it "allows changing the on_demand value" do
      visit spree.edit_admin_product_variant_path(product, variant)
      check "variant_on_demand"

      # on_hand reflects the change in on_demand
      expect(page).to have_field "variant_on_hand", with: "Infinity", disabled: true

      click_button 'Update'
      expect(page).to have_content %(Variant "#{product.name}" has been successfully updated!)
    end

    it "memorizes on_hand value previously entered if enabling and disabling on_demand" do
      visit spree.edit_admin_product_variant_path(product, variant)
      fill_in "variant_on_hand", with: "123"
      check "variant_on_demand"
      uncheck "variant_on_demand"

      # on_hand shows the memorized value, not the original DB value
      expect(page).to have_field "variant_on_hand", with: "123"
    end
  end

  it "soft-deletes variants" do
    product = create(:simple_product)
    variant = create(:variant, product:)

    login_as_admin
    visit spree.admin_product_variants_path product

    within "tr#spree_variant_#{variant.id}" do
      accept_alert do
        page.find('a.delete-resource').click
      end
    end

    expect(page).not_to have_selector "tr#spree_variant_#{variant.id}"
    expect(variant.reload.deleted_at).not_to be_nil
  end

  describe "editing variant attributes" do
    let!(:variant) { create(:variant) }
    let(:product) { variant.product }
    let!(:tax_category) { create(:tax_category) }

    before do
      login_as_admin
      visit spree.edit_admin_product_variant_path product, variant
    end

    it "editing display name for a variant" do
      # It should allow the display name to be changed
      expect(page).to have_field "variant_display_name"
      expect(page).to have_field "variant_display_as"

      # When I update the fields and save the variant
      fill_in "variant_display_name", with: "Display Name"
      fill_in "variant_display_as", with: "Display As This"
      click_button 'Update'
      expect(page).to have_content %(Variant "#{product.name}" has been successfully updated!)

      # Then the displayed values should have been saved
      expect(variant.reload.display_name).to eq("Display Name")
      expect(variant.display_as).to eq("Display As This")
    end

    it "editing weight for a variant" do
      # It should allow the weight to be changed
      expect(page).to have_field "unit_value_human"

      # When I update the fields and save the variant with invalid value
      fill_in "unit_value_human", with: "1.234"
      click_button 'Update'
      expect(page).not_to have_content %(Variant "#{product.name}" has been successfully updated!)

      fill_in "unit_value_human", with: "1.23"
      click_button 'Update'
      expect(page).not_to have_content %(Variant "#{product.name}" has been successfully updated!)

      # Then the displayed values should have been saved
      expect(variant.reload.unit_value).to eq(1.23)
    end

    context "editing variant tax category" do
      it "editing variant tax category" do
        select2_select tax_category.name, from: 'variant_tax_category_id'
        click_button 'Update'

        expect(variant.reload.tax_category).to eq tax_category
      end
    end
  end
end
