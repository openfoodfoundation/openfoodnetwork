# frozen_string_literal: true

require 'system_helper'

RSpec.describe "As a consumer, I want to check unit price information for a product" do
  include AuthenticationHelper
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper

  let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:oc1) {
    create(:simple_order_cycle, distributors: [distributor],
                                coordinator: create(:distributor_enterprise),
                                orders_close_at: 2.days.from_now)
  }
  let(:variant) { create(:variant, supplier:) }
  let(:order) { create(:order, distributor:) }
  let(:exchange1) { oc1.exchanges.to_enterprises(distributor).outgoing.first }
  let(:user) { create(:user, password: "password", password_confirmation: "password") }

  before do
    pick_order order
    exchange1.update_attribute :pickup_time, "monday"
    add_variant_to_order_cycle(exchange1, variant)
  end

  describe "for the shopfront" do
    before do
      visit shop_path
    end

    it "one click on the question mark icon should open the tooltip, " \
       "another click should close it" do
      expect(page).to have_selector '.variant-unit-price'
      within '.variant-unit-price' do
        expect(page).to have_selector '.question-mark-icon'
        expect(page).to have_content("$19,990.00 / kg") # displays the unit price value
      end
      find('.question-mark-icon').click
      expect(page).to have_selector '.joyride-tip-guide.question-mark-tooltip'
      within '.joyride-tip-guide.question-mark-tooltip' do
        expect(page).to have_content('This is the unit price of this product. ' \
                                     'It allows you to compare the price of products ' \
                                     'independent of packaging sizes & weights.')
      end

      page.find("body").click
      expect(page).not_to have_selector '.joyride-tip-guide.question-mark-tooltip'
      expect(page).not_to have_content('This is the unit price of this product. ' \
                                       'It allows you to compare the price of products ' \
                                       'independent of packaging sizes & weights.')
    end
  end

  describe "into the cart sidebar" do
    before do
      visit shop_path
      click_button "Add"
      toggle_cart
    end

    it "shows/hide the unit price information with the question mark icon in the sidebar" do
      expect(page).to have_selector ".cart-content .question-mark-icon"
      within ".cart-content" do
        expect(page).to have_content("$19,990.00 / kg") # displays the unit price value
        find(".question-mark-icon").click
      end
      expect(page).to have_selector '.joyride-tip-guide.question-mark-tooltip'
      within '.joyride-tip-guide.question-mark-tooltip' do
        expect(page).to have_content('This is the unit price of this product. ' \
                                     'It allows you to compare the price of products ' \
                                     'independent of packaging sizes & weights.')
      end
      page.find("body").click
      expect(page).not_to have_selector '.joyride-tip-guide.question-mark-tooltip'
      expect(page).not_to have_content('This is the unit price of this product. ' \
                                       'It allows you to compare the price of products ' \
                                       'independent of packaging sizes & weights.')

      expect(page).to have_content("$19,990.00 / kg")
    end
  end
end
