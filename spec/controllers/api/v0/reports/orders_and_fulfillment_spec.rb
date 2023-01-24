# frozen_string_literal: true

require "spec_helper"

describe Api::V0::ReportsController, type: :controller do
  let!(:address_within_zone) { create(:address, state_id: Spree::State.first.id) }
  let!(:address_outside_zone) { create(:address, state_id: Spree::State.second.id) }
  let!(:user_within_zone) {
    create(:user, bill_address_id: address_within_zone.id,
                  ship_address_id: address_within_zone.id)
  }
  let!(:user_outside_zone) {
    create(:user, bill_address_id: address_outside_zone.id,
                  ship_address_id: address_outside_zone.id)
  }
  let!(:zone) { create(:zone_with_state_member, name: 'Victoria', default_tax: true) }
  let!(:tax_category) { create(:tax_category, name: "Veggies", is_default: "f") }
  let!(:tax_rate) {
    create(:tax_rate, name: "Tax rate - included or not", amount: 0.13,
                      zone_id: zone.id, tax_category_id: tax_category.id, included_in_price: true)
  }
  let!(:distributor) { create(:distributor_enterprise, charges_sales_tax: true) }
  let(:supplier) { create(:supplier_enterprise) }
  let!(:product_with_tax) {
    create(:simple_product, supplier: supplier, price: 10, tax_category_id: tax_category.id)
  }
  let!(:variant_with_tax) { product_with_tax.variants.first }
  let!(:order_cycle) {
    create(:simple_order_cycle, suppliers: [supplier], distributors: [distributor],
                                coordinator: distributor, variants: [variant_with_tax])
  }
  let!(:free_shipping) {
    create(:shipping_method, distributors: [distributor], require_ship_address: true,
                             name: "Delivery", description: "Payment without fee",
                             calculator: Calculator::FlatRate.new(preferred_amount: 0.00))
  }
  let!(:free_payment) {
    create(:payment_method, distributors: [distributor],
                            name: "Payment without Fee", description: "Payment without fee",
                            calculator: Calculator::FlatRate.new(preferred_amount: 0.00))
  }
  let!(:order_within_zone) {
    create(:order, order_cycle: order_cycle, distributor: distributor, user: user_within_zone,
                   bill_address: address_within_zone, ship_address: address_within_zone,
                   state: "cart", line_items: [create(:line_item, variant: variant_with_tax)])
  }
  let!(:order_outside_zone) {
    create(:order, order_cycle: order_cycle, distributor: distributor, user: user_outside_zone,
                   bill_address: address_outside_zone, ship_address: address_outside_zone,
                   state: "cart", line_items: [create(:line_item, variant: variant_with_tax)])
  }

  before do
    allow(controller).to receive(:spree_current_user) { current_user }
    order_within_zone.finalize!
    order_outside_zone.finalize!
  end

  describe "orders and fulfillment report" do
    let(:params) {
      {
        report_type: 'orders_and_fulfillment',
        reports_subtype: 'order_cycle_supplier_totals',
        q: { completed_at_gt: Time.zone.now - 1.day, completed_at_lt: Time.zone.now + 1.day },
        fields_to_hide: [:none]
      }
    }

    context "as an enterprise user with full order permissions (distributor)" do
      let(:current_user) { distributor.owner }

      it "renders results for an order with taxes" do
        api_get :show, params

        expect(response.status).to eq 200
      end
    end
  end
end
