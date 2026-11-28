# frozen_string_literal: true

RSpec.describe LineItemsController do
  let(:user) { create(:user) }
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle) }

  context "listing bought items" do
    let!(:completed_order) do
      order = create(:completed_order_with_totals, user:, distributor:,
                                                   order_cycle:, line_items_count: 1)
      Orders::WorkflowService.new(order).complete!
      order
    end

    before do
      allow(controller).to receive_messages spree_current_user: user
      allow(controller).to receive_messages current_order_cycle: order_cycle
      allow(controller).to receive_messages current_distributor: distributor
    end

    it "lists items bought by the user from the same shop in the same order_cycle" do
      get :bought, format: :json
      expect(response).to have_http_status :ok
      json_response = response.parsed_body
      expect(json_response.length).to eq completed_order.line_items.reload.count
      expect(json_response[0]['id']).to eq completed_order.line_items.first.id
    end
  end

  describe "destroying a line item" do
    context "on a completed order with shipping and payment fees" do
      let(:zone) { create(:zone_with_member) }
      let(:shipping_tax_rate) do
        create(:tax_rate, included_in_price: true,
                          calculator: Calculator::DefaultTax.new,
                          amount: 0.25,
                          zone:)
      end
      let(:shipping_tax_category) { create(:tax_category, tax_rates: [shipping_tax_rate]) }
      let(:shipping_fee) { 3 }
      let(:payment_fee) { 5 }
      let(:distributor_with_taxes) { create(:distributor_enterprise_with_tax) }
      let(:order) {
        create(:completed_order_with_fees, distributor: distributor_with_taxes,
                                           shipping_fee:, payment_fee:,
                                           shipping_tax_category:)
      }

      before do
        allow(order).to receive(:tax_zone) { zone }
        order.reload
        order.create_tax_charge!
      end

      it "updates the fees" do
        # Sanity check fees
        item_num = order.line_items.length
        initial_fees = item_num * (shipping_fee + payment_fee)

        expect(order.shipment.adjustments.tax.count).to eq 1
        expect(order.shipment.included_tax_total).to eq 1.2

        # Delete the item
        item = order.line_items.first
        allow(controller).to receive_messages spree_current_user: order.user
        delete :destroy, format: :json, params: { id: item }
        expect(response).to have_http_status :no_content

        # Check the fees again
        order.reload
        order.shipment.reload
        expect(order.adjustment_total).to eq initial_fees - shipping_fee - payment_fee
        expect(order.shipment.adjustment_total).to eq shipping_fee
        expect(order.payments.first.adjustment.amount).to eq payment_fee
        expect(order.shipment.included_tax_total).to eq 0.6
      end
    end

    context "on a completed order with enterprise fees" do
      let(:user) { create(:user) }
      let(:variant1) { create(:variant) }
      let(:variant2) { create(:variant) }
      let(:distributor) { create(:distributor_enterprise, :allowing_all_order_changes) }
      let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
      let(:calculator) {
        Calculator::PriceSack.new(preferred_minimal_amount: 15, preferred_normal_amount: 22,
                                  preferred_discount_amount: 11)
      }
      let(:enterprise_fee) { create(:enterprise_fee, calculator:) }
      let!(:exchange) {
        create(:exchange, incoming: true, sender: variant1.enterprise,
                          receiver: order_cycle.coordinator, variants: [variant1, variant2],
                          enterprise_fees: [enterprise_fee])
      }
      let!(:order) do
        order = create(:completed_order_with_totals, user:, distributor:,
                                                     order_cycle:, line_items_count: 2)
        order.reload.line_items.first.update(variant_id: variant1.id)
        order.line_items.last.update(variant_id: variant2.id)
        Orders::WorkflowService.new(order).complete!
        order.recreate_all_fees!
        order
      end
      let(:params) { { format: :json, id: order.line_items.first } }

      it "updates the fees" do
        expect(order.reload.adjustment_total).to eq calculator.preferred_discount_amount

        allow(controller).to receive_messages spree_current_user: user
        delete(:destroy, params:)
        expect(response).to have_http_status :no_content

        expect(order.reload.adjustment_total).to eq calculator.preferred_normal_amount
      end
    end
  end
end
