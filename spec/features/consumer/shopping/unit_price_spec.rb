require 'spec_helper'

feature "As a consumer, I want to check unit price information for a product", js: true do
  include AuthenticationHelper
  include WebHelper
  include ShopWorkflow
  include UIComponentHelper

  let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let(:supplier) { create(:supplier_enterprise) }
  let(:oc1) { create(:simple_order_cycle, distributors: [distributor], coordinator: create(:distributor_enterprise), orders_close_at: 2.days.from_now) }
  let(:product) { create(:simple_product, supplier: supplier) }
  let(:variant) { product.variants.first }
  let(:order) { create(:order, distributor: distributor) }
  let(:exchange1) { oc1.exchanges.to_enterprises(distributor).outgoing.first }
  let(:user) { create(:user, password: "password", password_confirmation: "password") }

  before do
    set_order order
    exchange1.update_attribute :pickup_time, "monday"
    add_variant_to_order_cycle(exchange1, variant)
    allow(OpenFoodNetwork::FeatureToggle)
      .to receive(:enabled?).with(:unit_price, anything) { true }
  end

  describe "for the shopfront" do
    before do
      visit shop_path
    end

    it "one click on the question mark icon should open the tooltip, another click should close it" do
      expect(page).to have_selector '.variant-unit-price'
      within '.variant-unit-price' do 
        expect(page).to have_selector '.question-mark-icon'
      end
      find('.question-mark-icon').click
      expect(page).to have_selector '.joyride-tip-guide.question-mark-tooltip'
      within '.joyride-tip-guide.question-mark-tooltip' do 
        expect(page).to have_content I18n.t('js.shopfront.unit_price_tooltip')
      end

      page.find("body").click
      expect(page).not_to have_selector '.joyride-tip-guide.question-mark-tooltip'
      expect(page).to have_no_content I18n.t('js.shopfront.unit_price_tooltip')
    end

  end
end
