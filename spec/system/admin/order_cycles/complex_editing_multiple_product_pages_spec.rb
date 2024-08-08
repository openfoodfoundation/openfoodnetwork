# frozen_string_literal: true

require 'system_helper'

RSpec.describe '
    As an administrator
    I want to manage complex order cycles
' do
  include AdminHelper
  include AuthenticationHelper
  include WebHelper

  describe "editing an order cycle with multiple pages of products" do
    let(:order_cycle) { create(:order_cycle) }
    let(:supplier_enterprise) { order_cycle.exchanges.incoming.first.sender }
    let!(:new_product) {
      create(
        :product,
        supplier_id: supplier_enterprise.id,
        name: "Z Last Product", # ordered by name
      )
    }

    before do
      stub_const("#{Api::V0::ExchangeProductsController}::DEFAULT_PER_PAGE", 1)

      login_as_admin
      visit admin_order_cycle_incoming_path(order_cycle)
      expect(page).to have_content "1 / 2 selected"

      page.find("tr.supplier-#{supplier_enterprise.id} td.products").click
      expect(page).to have_selector ".exchange-product-details"

      expect(page).to have_content "1 of 2 Variants Loaded"
      expect(page).not_to have_content "Z Last Product"
    end

    it "load all products" do
      page.find(".exchange-load-all-variants a").click

      expect_all_products_loaded
    end

    it "select all products" do
      check "Select All 2 Variants"

      expect_all_products_loaded

      within("div.exchange-product", text: "Z Last Product") do
        expect(page).to have_checked_field "1g", disabled: false
      end
    end

    def expect_all_products_loaded
      expect(page).to have_content new_product.name
      expect(page).to have_content "2 of 2 Variants Loaded"
    end
  end
end
