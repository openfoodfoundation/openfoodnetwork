# frozen_string_literal: true

require 'spec_helper'

describe LineItemsController, type: :controller do
  let(:user) { create(:user) }
  let(:distributor) { create(:distributor_enterprise) }
  let(:order_cycle) { create(:simple_order_cycle) }

  context "listing bought items" do
    let!(:completed_order) do
      order = create(:completed_order_with_totals, user: user, distributor: distributor,
                                                   order_cycle: order_cycle, line_items_count: 1)
      break unless order.next! while !order.completed?
      order
    end

    before do
      allow(controller).to receive_messages spree_current_user: user
      allow(controller).to receive_messages current_order_cycle: order_cycle
      allow(controller).to receive_messages current_distributor: distributor
    end

    it "lists items bought by the user from the same shop in the same order_cycle" do
      get :bought, format: :json
      expect(response.status).to eq 200
      json_response = JSON.parse(response.body)
      expect(json_response.length).to eq completed_order.line_items.reload.count
      expect(json_response[0]['id']).to eq completed_order.line_items.first.id
    end
  end

  describe "destroying a line item" do
    context "on a completed order" do
      let(:item) do
        order = create(:completed_order_with_totals)
        item = create(:line_item, order: order)
        break unless order.next! while !order.completed?
        item
      end

      let(:order) { item.order }
      let(:order_cycle) {
        create(:simple_order_cycle, distributors: [distributor],
                                    variants: [order.line_item_variants])
      }

      before { allow(controller).to receive_messages spree_current_user: item.order.user }

      context "with a line item id" do
        let(:params) { { format: :json, id: item } }

        context "where the item's order is not associated with the user" do
          it "denies deletion" do
            delete :destroy, params: params
            expect(response.status).to eq 403
          end
        end

        context "where the item's order is associated with the current user" do
          before do
            order.update!(user_id: user.id)
            allow(controller).to receive_messages spree_current_user: item.order.user
          end

          context "without an order cycle or distributor" do
            it "denies deletion" do
              delete :destroy, params: params
              expect(response.status).to eq 403
            end
          end

          context "with an order cycle and distributor" do
            before { order.update!(order_cycle_id: order_cycle.id, distributor_id: distributor.id) }

            context "where changes are not allowed" do
              it "denies deletion" do
                delete :destroy, params: params
                expect(response.status).to eq 403
              end
            end

            context "where changes are allowed" do
              before { distributor.update!(allow_order_changes: true) }

              it "deletes the line item" do
                delete :destroy, params: params
                expect(response.status).to eq 204
                expect { item.reload }.to raise_error ActiveRecord::RecordNotFound
              end

              context "after a payment is captured" do
                let(:payment) {
                  create(:check_payment, :completed, amount: order.total, order: order)
                }
                before { payment.capture! }

                it 'updates the payment state' do
                  expect(order.payment_state).to eq 'paid'
                  delete :destroy, params: params
                  order.reload
                  expect(order.payment_state).to eq 'credit_owed'
                end
              end
            end
          end
        end
      end
    end

    context "on a completed order with shipping and payment fees" do
      let(:zone) { create(:zone_with_member) }
      let(:shipping_tax_rate) do
        create(:tax_rate, included_in_price: true,
                          calculator: Calculator::DefaultTax.new,
                          amount: 0.25,
                          zone: zone)
      end
      let(:shipping_tax_category) { create(:tax_category, tax_rates: [shipping_tax_rate]) }
      let(:shipping_fee) { 3 }
      let(:payment_fee) { 5 }
      let(:distributor_with_taxes) { create(:distributor_enterprise_with_tax) }
      let(:order) {
        create(:completed_order_with_fees, distributor: distributor_with_taxes,
                                           shipping_fee: shipping_fee, payment_fee: payment_fee,
                                           shipping_tax_category: shipping_tax_category)
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
        expect(response.status).to eq 204

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
      let(:distributor) { create(:distributor_enterprise, allow_order_changes: true) }
      let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
      let(:calculator) {
        Calculator::PriceSack.new(preferred_minimal_amount: 15, preferred_normal_amount: 22,
                                  preferred_discount_amount: 11)
      }
      let(:enterprise_fee) { create(:enterprise_fee, calculator: calculator) }
      let!(:exchange) {
        create(:exchange, incoming: true, sender: variant1.product.supplier,
                          receiver: order_cycle.coordinator, variants: [variant1, variant2],
                          enterprise_fees: [enterprise_fee])
      }
      let!(:order) do
        order = create(:completed_order_with_totals, user: user, distributor: distributor,
                                                     order_cycle: order_cycle, line_items_count: 2)
        order.reload.line_items.first.update(variant_id: variant1.id)
        order.line_items.last.update(variant_id: variant2.id)
        break unless order.next! while !order.completed?
        order.recreate_all_fees!
        order
      end
      let(:params) { { format: :json, id: order.line_items.first } }

      it "updates the fees" do
        expect(order.reload.adjustment_total).to eq calculator.preferred_discount_amount

        allow(controller).to receive_messages spree_current_user: user
        delete :destroy, params: params
        expect(response.status).to eq 204

        expect(order.reload.adjustment_total).to eq calculator.preferred_normal_amount
      end
    end
  end
end
