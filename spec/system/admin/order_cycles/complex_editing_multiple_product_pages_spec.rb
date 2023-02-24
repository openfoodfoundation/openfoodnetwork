# frozen_string_literal: true

require 'system_helper'

describe '
    As an administrator
    I want to manage complex order cycles
' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  describe "editing an order cycle with multiple pages of products" do
    let(:order_cycle) { create(:order_cycle) }
    let(:supplier_enterprise) { order_cycle.exchanges.incoming.first.sender }
    let!(:new_product) { create(:product, supplier: supplier_enterprise) }

    before do
      stub_const("#{Api::V0::ExchangeProductsController}::DEFAULT_PER_PAGE", 1)

      login_as_admin_and_visit admin_order_cycle_incoming_path(order_cycle)
      expect(page).to have_content "1 / 2 selected"

      page.find("tr.supplier-#{supplier_enterprise.id} td.products").click
      expect(page).to have_selector ".exchange-product-details"

      expect(page).to have_content "1 of 2 Variants Loaded"
      expect(page).to_not have_content new_product.name
    end

    it "load all products" do
      page.find(".exchange-load-all-variants a").click

      expect_all_products_loaded
    end

    it "select all products" do
      # replace with scroll_to method when upgrading to Capybara >= 3.13.0
      checkbox_id = "order_cycle_incoming_exchange_0_select_all_variants"
      page.execute_script("document.getElementById('#{checkbox_id}').scrollIntoView()")
      check checkbox_id

      expect_all_products_loaded

      expect(page).to have_checked_field "order_cycle_incoming_exchange_0_variants_#{new_product.variants.first.id}",
                                         disabled: false
    end

    def expect_all_products_loaded
      expect(page).to have_content new_product.name.upcase
      expect(page).to have_content "2 of 2 Variants Loaded"
    end
  end
end
