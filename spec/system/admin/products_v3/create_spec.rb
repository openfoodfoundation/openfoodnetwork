# frozen_string_literal: true

require "system_helper"

RSpec.describe 'As an enterprise user, I can manage my products' do
  include AuthenticationHelper
  include WebHelper

  let!(:supplier) { create(:supplier_enterprise) }
  # Creating another producer such that producer column is visible
  # otherwise on one producer, it's hidden by default
  let!(:supplier2) { create(:supplier_enterprise) }
  let!(:taxon) { create(:taxon) }

  describe "creating a new product" do
    let!(:distributor) { create(:distributor_enterprise) }
    let!(:shipping_category) { create(:shipping_category) }

    before { visit_products_page_as_admin }

    it "creating a new product" do
      find("a", text: "New Product").click
      expect(page).to have_content "New Product"
      fill_in 'product_name', with: 'Big Bag Of Apples'
      tomselect_select supplier.name, from: 'product[supplier_id]'
      select_tom_select 'Weight (g)', from: 'product_variant_unit_field'
      fill_in 'product_unit_value', with: '100'
      fill_in 'product_price', with: '10.00'
      # TODO dropdowns below are still using select2:
      select taxon.name, from: 'product_primary_taxon_id' # ...instead of tom-select
      select shipping_category.name, from: 'product_shipping_category_id' # ...instead of tom-select
      click_button 'Create'
      expect(URI.parse(current_url).path).to eq spree.admin_products_path
      expect(flash_message).to eq 'Product "Big Bag Of Apples" has been successfully created!'
      expect(page).to have_field "_products_0_name", with: 'Big Bag Of Apples'
    end
  end

  describe "creating new variants" do
    let!(:product) { create(:product) }

    before { visit_products_page_as_admin }

    it "hovering over the New variant button displays the text" do
      new_variant_button
      find("button.secondary.condensed.naked.icon-plus").hover
      new_variant_button(visible: true)
      expect(page).to have_content "New variant"
    end

    it "has the empty unit value for the new variant display_as by default" do
      new_variant_button.click

      within new_variant_row do
        unit_button = find('button[aria-label="Unit"]')
        expect(unit_button.text.strip).to eq('')

        unit_button.click
        expect(page).to have_field "Display unit as", placeholder: ""
      end
    end

    shared_examples "creating a new variant (bulk)" do |stock|
      it "handles the #{stock} behaviour" do
        # the product and the default variant is displayed
        expect(page).to have_selector("input[aria-label=Name][value='#{product.name}']",
                                      visible: true, count: 1)
        expect(page).to have_selector("input[aria-label=Name][placeholder='#{product.name}']",
                                      visible: false, count: 1)

        # when a second variant is added, the number of lines increases
        expect {
          find("button.secondary.condensed.naked.icon-plus").click
        }.to change{
          page.all("input[aria-label=Name][placeholder='#{product.name}']", visible: false).count
        }.from(1).to(2)

        # When I fill out variant details and hit update
        within page.all("tr.condensed")[1] do # selects second variant row
          find('input[id$="_sku"]').fill_in with: "345"
          find('input[id$="_display_name"]').fill_in with: "Small bag"
          tomselect_select "Weight (g)", from: "Unit scale"
          find('button[id$="unit_to_display"]').click # opens the unit value pop out
          find('input[id$="_unit_value_with_description"]').fill_in with: "0.002"
          find('input[id$="_display_as"]').fill_in with: "2 grams"
          find('button[aria-label="On Hand"]').click
          find('input[id$="_price"]').fill_in with: "11.1"

          select supplier.name, from: 'Producer'
          select taxon.name, from: 'Category'

          if stock == "on_hand"
            find('input[id$="_on_hand_desired"]').fill_in with: "66"
          elsif stock == "on_demand"
            find('input[id$="_on_demand_desired"]').check
          end
        end

        expect(page).to have_content "1 product modified."

        expect {
          click_on "Save changes"
          expect(page).to have_content "Changes saved"
        }.to change {
               Spree::Variant.count
             }.from(1).to(2)

        click_on "Dismiss"
        expect(page).not_to have_content "Changes saved"

        new_variant = Spree::Variant.where(deleted_at: nil).last
        expect(new_variant.sku).to eq "345"
        expect(new_variant.display_name).to eq "Small bag"
        expect(new_variant.variant_unit).to eq "weight"
        expect(new_variant.variant_unit_scale).to eq 1 # g
        expect(new_variant.unit_value).to eq 0.002
        expect(new_variant.display_as).to eq "2 grams"
        expect(new_variant.unit_presentation).to eq "2 grams"
        expect(new_variant.price).to eq 11.1
        if stock == "on_hand"
          expect(new_variant.on_hand).to eq 66
        elsif stock == "on_demand"
          expect(new_variant.on_demand).to eq true
        end

        within page.all("tr.condensed")[1] do # selects second variant row
          page.find('input[id$="_sku"]').fill_in with: "789"
        end

        accept_confirm do
          click_on "Discard changes" # does not save chages
        end
        expect(page).not_to have_content "Changes saved"
      end
    end

    it_behaves_like "creating a new variant (bulk)", "on_hand"
    it_behaves_like "creating a new variant (bulk)", "on_demand"
  end

  def visit_products_page_as_admin
    login_as_admin
    visit spree.admin_products_path
  end

  def new_variant_button(visible: false)
    page.find('button[aria-label="New variant"]', text: "New variant", visible:)
  end

  def new_variant_row
    'tr[data-new-record="true"]'
  end
end
