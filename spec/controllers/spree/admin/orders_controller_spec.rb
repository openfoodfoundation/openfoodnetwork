# frozen_string_literal: true

require 'spec_helper'

describe Spree::Admin::OrdersController, type: :controller do
  describe "#edit" do
    let!(:order) { create(:order_with_totals_and_distribution, ship_address: create(:address)) }

    before { controller_login_as_admin }

    describe "view" do
      render_views

      it "does not show ineligible payment adjustments" do
        adjustment = create(
          :adjustment,
          adjustable: build(:payment),
          originator_type: "Spree::PaymentMethod",
          label: "invalid adjustment",
          eligible: false,
          order: order,
          amount: 0
        )

        spree_get :edit, id: order

        expect(response.body).to_not match adjustment.label
      end
    end
  end

  context "#update" do
    let(:params) do
      { id: order,
        order: { number: order.number,
                 distributor_id: order.distributor_id,
                 order_cycle_id: order.order_cycle_id } }
    end

    before { controller_login_as_admin }

    context "complete order" do
      let(:order) { create :completed_order_with_totals }

      it "does not throw an error if no order object is given in params" do
        params = { id: order }

        spree_put :update, params

        expect(response.status).to eq 302
      end

      context "recalculating fees and taxes" do
        before do
          allow(Spree::Order).to receive_message_chain(:includes, :find_by!) { order }
        end

        it "updates fees and taxes and redirects to order details page" do
          expect(order).to receive(:recreate_all_fees!)
          expect(order).to receive(:create_tax_charge!).at_least :once

          spree_put :update, params

          expect(response).to redirect_to spree.edit_admin_order_path(order)
        end
      end

      context "recalculating enterprise fees" do
        let(:user) { create(:admin_user) }
        let(:variant1) { create(:variant) }
        let(:variant2) { create(:variant) }
        let(:distributor) {
          create(:distributor_enterprise, allow_order_changes: true, charges_sales_tax: true)
        }
        let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
        let(:enterprise_fee) { create(:enterprise_fee, calculator: build(:calculator_per_item) ) }
        let!(:exchange) {
          create(:exchange, incoming: true, sender: variant1.product.supplier,
                            receiver: order_cycle.coordinator, variants: [variant1, variant2],
                            enterprise_fees: [enterprise_fee])
        }
        let!(:order) do
          order = create(:completed_order_with_totals, line_items_count: 2,
                                                       distributor: distributor,
                                                       order_cycle: order_cycle)
          order.reload.line_items.first.update(variant_id: variant1.id)
          order.line_items.last.update(variant_id: variant2.id)
          break unless order.next! while !order.completed?
          order.recreate_all_fees!
          order
        end

        before do
          allow(controller).to receive(:spree_current_user) { user }
          allow(controller).to receive(:order_to_update) { order }
        end

        it "recalculates fees if the orders contents have changed" do
          expect(order.total)
            .to eq order.item_total + (enterprise_fee.calculator.preferred_amount * 2)
          expect(order.adjustment_total).to eq enterprise_fee.calculator.preferred_amount * 2

          order.contents.add(order.line_items.first.variant, 1)

          spree_put :update, { id: order.number }

          expect(order.reload.total)
            .to eq order.item_total + (enterprise_fee.calculator.preferred_amount * 3)
          expect(order.adjustment_total).to eq enterprise_fee.calculator.preferred_amount * 3
        end

        context "if the associated enterprise fee record is soft-deleted" do
          it "removes adjustments for deleted enterprise fees" do
            fee_amount = enterprise_fee.calculator.preferred_amount

            expect(order.total).to eq order.item_total + (fee_amount * 2)
            expect(order.adjustment_total).to eq fee_amount * 2

            enterprise_fee.destroy

            spree_put :update, { id: order.number }

            expect(order.reload.total).to eq order.item_total
            expect(order.adjustment_total).to eq 0
          end
        end

        context "if the associated enterprise fee record is hard-deleted" do
          # Note: Enterprise fees are soft-deleted now, but we still have hard-deleted
          # enterprise fees referenced as the originator of some adjustments (in production).
          it "removes adjustments for deleted enterprise fees" do
            fee_amount = enterprise_fee.calculator.preferred_amount

            expect(order.total).to eq order.item_total + (fee_amount * 2)
            expect(order.adjustment_total).to eq fee_amount * 2

            enterprise_fee.really_destroy!

            spree_put :update, { id: order.number }

            expect(order.reload.total).to eq order.item_total
            expect(order.adjustment_total).to eq 0
          end
        end

        context "with taxes on enterprise fees" do
          let(:zone) { create(:zone_with_member) }
          let(:tax_included) { true }
          let(:tax_rate) {
            create(:tax_rate, amount: 0.25, included_in_price: tax_included, zone: zone)
          }
          let!(:enterprise_fee) {
            create(:enterprise_fee, tax_category: tax_rate.tax_category, amount: 1)
          }

          before do
            allow(order).to receive(:tax_zone) { zone }
          end

          context "with included taxes" do
            it "taxes fees correctly" do
              spree_put :update, { id: order.number }
              order.reload

              expect(order.all_adjustments.tax.count).to eq 2
              expect(order.enterprise_fee_tax).to eq 0.4

              expect(order.included_tax_total).to eq 0.4
              expect(order.additional_tax_total).to eq 0
            end
          end

          context "with added taxes" do
            let(:tax_included) { false }

            it "taxes fees correctly" do
              spree_put :update, { id: order.number }
              order.reload

              expect(order.all_adjustments.tax.count).to eq 2
              expect(order.enterprise_fee_tax).to eq 0.5

              expect(order.included_tax_total).to eq 0
              expect(order.additional_tax_total).to eq 0.5
            end

            context "when the order has legacy taxes" do
              let(:legacy_tax_adjustment) {
                create(:adjustment, amount: 0.5, included: false, originator: tax_rate,
                                    order: order, adjustable: order, state: "closed")
              }

              before do
                order.all_adjustments.tax.delete_all
                order.adjustments << legacy_tax_adjustment
              end

              it "removes legacy tax adjustments before recalculating tax" do
                expect(order.all_adjustments.tax.count).to eq 1
                expect(order.all_adjustments.tax).to include legacy_tax_adjustment
                expect(order.additional_tax_total).to eq 0.5

                spree_put :update, { id: order.number }
                order.reload

                expect(order.all_adjustments.tax.count).to eq 2
                expect(order.all_adjustments.tax).to_not include legacy_tax_adjustment
                expect(order.additional_tax_total).to eq 0.5
              end
            end
          end
        end
      end
    end

    context "incomplete order" do
      let(:order) { create(:order) }
      let(:line_item) { create(:line_item) }

      context "without line items" do
        it "redirects to order details page with flash error" do
          spree_put :update, params

          expect(flash[:error]).to eq "Line items can't be blank"
          expect(response).to redirect_to spree.edit_admin_order_path(order)
        end
      end

      context "with line items" do
        let!(:distributor){ create(:distributor_enterprise) }
        let!(:shipment){ create(:shipment) }
        let!(:order_cycle){
          create(:simple_order_cycle, distributors: [distributor], variants: [line_item.variant])
        }

        before do
          line_item.product.supplier = distributor
          order.shipments << shipment
          order.line_items << line_item
          distributor.shipping_methods << shipment.shipping_method
          order.select_shipping_method(shipment.shipping_method.id)
          order.save!
          params[:order][:distributor_id] = distributor.id
          params[:order][:order_cycle_id] = order_cycle.id
          params[:order][:line_items_attributes] =
            [{ id: line_item.id, quantity: line_item.quantity }]
        end

        context "and no errors" do
          it "updates distribution charges and redirects to payments  page" do
            expect_any_instance_of(Spree::Order).to receive(:recreate_all_fees!)
            allow_any_instance_of(Spree::Order)
              .to receive(:ensure_available_shipping_rates).and_return(true)

            expect {
              spree_put :update, params
            }.to change { order.reload.state }.from("cart").to("payment")
            expect(response).to redirect_to spree.admin_order_payments_path(order)
          end
        end

        context "with invalid distributor" do
          it "redirects to order details page with flash error" do
            params[:order][:distributor_id] = create(:distributor_enterprise).id

            spree_put :update, params

            expect(flash[:error])
              .to eq "Distributor or order cycle cannot supply the products in your cart"
            expect(response).to redirect_to spree.edit_admin_order_path(order)
          end
        end
      end
    end
  end

  describe "#index" do
    context "as a regular user" do
      before { allow(controller).to receive(:spree_current_user) { create(:user) } }

      it "should deny me access to the index action" do
        spree_get :index
        expect(response).to redirect_to unauthorized_path
      end
    end

    context "as an enterprise user" do
      let!(:order) { create(:order_with_distributor) }

      before { allow(controller).to receive(:spree_current_user) { order.distributor.owner } }

      it "should allow access" do
        expect(response.status).to eq 200
      end
    end
  end
end
