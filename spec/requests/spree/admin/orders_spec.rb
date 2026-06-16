# frozen_string_literal: true

RSpec.describe Spree::Admin::OrdersController do
  let(:admin) { create(:admin_user) }

  describe "#edit" do
    let!(:order) { create(:order_with_totals_and_distribution, ship_address: create(:address)) }

    before { sign_in admin }

    describe "view" do
      it "does not show ineligible payment adjustments" do
        adjustment = create(
          :adjustment,
          adjustable: build(:payment),
          originator_type: "Spree::PaymentMethod",
          label: "invalid adjustment",
          eligible: false,
          order:,
          amount: 0
        )

        get "/admin/orders/#{order.id}/edit"

        expect(response.body).not_to match adjustment.label
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

    before { sign_in admin }

    context "complete order" do
      let(:order) { create :completed_order_with_totals }

      it "does not throw an error if no order object is given in params" do
        put "/admin/orders/#{order.number}"

        expect(response).to have_http_status :found
      end

      context "recalculating fees and taxes" do
        before do
          allow(Spree::Order).to receive_message_chain(:includes, :find_by!) { order }
        end

        it "updates fees and taxes and redirects to order details page" do
          expect(order).to receive(:recreate_all_fees!)
          expect(order).to receive(:create_tax_charge!).at_least :once

          put("/admin/orders/#{order.id}", params:)

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
          create(:exchange, incoming: true, sender: variant1.supplier,
                            receiver: order_cycle.coordinator, variants: [variant1, variant2],
                            enterprise_fees: [enterprise_fee])
        }
        let!(:order) do
          order = create(:completed_order_with_totals, line_items_count: 2,
                                                       distributor:,
                                                       order_cycle:)
          order.reload.line_items.first.update(variant_id: variant1.id)
          order.line_items.last.update(variant_id: variant2.id)
          Orders::WorkflowService.new(order).complete!
          order.recreate_all_fees!
          order
        end

        it "recalculates fees if the orders contents have changed" do
          expect(order.total)
            .to eq order.item_total + (enterprise_fee.calculator.preferred_amount * 2)
          expect(order.adjustment_total).to eq enterprise_fee.calculator.preferred_amount * 2

          order.contents.add(order.line_items.first.variant, 1)

          put("/admin/orders/#{order.number}")

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

            put("/admin/orders/#{order.number}")

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

            put("/admin/orders/#{order.number}")

            expect(order.reload.total).to eq order.item_total
            expect(order.adjustment_total).to eq 0
          end
        end

        context "with taxes on enterprise fees" do
          let(:zone) { create(:zone_with_member) }
          let(:tax_included) { true }
          let(:tax_rate) {
            create(:tax_rate, amount: 0.25, included_in_price: tax_included, zone:)
          }
          let!(:enterprise_fee) {
            create(:enterprise_fee, tax_category: tax_rate.tax_category, amount: 1)
          }

          before do
            allow(order).to receive(:tax_zone) { zone }
          end

          context "with included taxes" do
            it "taxes fees correctly" do
              put("/admin/orders/#{order.number}")

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
              put("/admin/orders/#{order.number}")

              order.reload
              expect(order.all_adjustments.tax.count).to eq 2
              expect(order.enterprise_fee_tax).to eq 0.5

              expect(order.included_tax_total).to eq 0
              expect(order.additional_tax_total).to eq 0.5
            end

            context "when the order has legacy taxes" do
              let(:legacy_tax_adjustment) {
                create(:adjustment, amount: 0.5, included: false, originator: tax_rate,
                                    order:, adjustable: order, state: "closed")
              }

              before do
                order.all_adjustments.tax.delete_all
                order.adjustments << legacy_tax_adjustment
              end

              it "removes legacy tax adjustments before recalculating tax" do
                expect(order.all_adjustments.tax.count).to eq 1
                expect(order.all_adjustments.tax).to include legacy_tax_adjustment
                expect(order.additional_tax_total).to eq 0.5

                put("/admin/orders/#{order.number}")

                order.reload
                expect(order.all_adjustments.tax.count).to eq 2
                expect(order.all_adjustments.tax).not_to include legacy_tax_adjustment
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
          put("/admin/orders/#{order.number}", params:)

          expect(flash[:error]).to eq "Line items can't be blank"
          expect(response).to redirect_to spree.edit_admin_order_path(order)
        end
      end

      context "when order is shipped" do
        it "redirects to order details page with flash error" do
          order.update(shipment_state: :ready)
          order.update(shipment_state: :shipped)
          put("/admin/orders/#{order.number}")

          expect(flash[:error]).to eq "Cannot add item to shipped order"
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
          line_item.supplier = distributor
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
              put("/admin/orders/#{order.number}", params:)
            }.to change { order.reload.state }.from("cart").to("payment")
            expect(response).to redirect_to spree.admin_order_payments_path(order)
          end
        end

        context "with invalid distributor" do
          it "redirects to order details page with flash error" do
            params[:order][:distributor_id] = create(:distributor_enterprise).id

            put("/admin/orders/#{order.number}", params:)

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
      before { sign_in create(:user) }

      it "denies access to the index action" do
        get "/admin/orders"

        expect(response).to redirect_to unauthorized_path
      end
    end

    context "as an enterprise user" do
      let!(:order) { create(:order_with_distributor) }

      before { sign_in order.distributor.owner }

      it "allows access" do
        get "/admin/orders"

        expect(response).to have_http_status :ok
      end
    end
  end

  describe "#fire" do
    let(:order) { create(:completed_order_with_totals) }
    let(:headers) { { HTTP_REFERER: spree.edit_admin_order_path(order) } }

    before do
      sign_in admin

      allow(Spree::Order).to receive_message_chain(:includes, :find_by!).and_return(order)
    end

    %w{cancel resume}.each do |event|
      it "calls allowed event #{event}" do
        expect(order).to receive(:public_send).with(event)

        get("/admin/orders/#{order.number}/fire", params: { e: event }, headers:)

        expect(response).to redirect_to spree.edit_admin_order_path(order)
      end
    end

    it "returns a success flash message" do
      get("/admin/orders/#{order.number}/fire", params: { e: "cancel" }, headers:)

      expect(flash[:success]).to eq "Order Updated"
    end

    it "amends back order" do
      expect(AmendBackorderJob).to receive(:perform_later)

      get("/admin/orders/#{order.number}/fire", params: { e: "cancel" }, headers:)
    end

    context "with a non allowed event" do
      it "returns an error" do
        expect(order).not_to receive(:public_send).with("state")

        get("/admin/orders/#{order.number}/fire", params: { e: "state" }, headers:)

        expect(flash[:error]).to eq "Can not perform this operation"
        expect(response).to redirect_to spree.edit_admin_order_path(order)
      end
    end

    context "when a GatewayError is raised" do
      it "returns an error flash message" do
        allow(order).to receive(:public_send).and_raise(Spree::Core::GatewayError, "Some error")

        get("/admin/orders/#{order.number}/fire", params: { e: "cancel" }, headers:)

        expect(flash[:error]).to eq "Some error"
        expect(response).to redirect_to spree.edit_admin_order_path(order)
      end
    end
  end

  describe "#bulk_credit" do
    let(:order) { create(:order_with_totals, payment_state: "credit_owed", distributor:) }
    let(:order1) { create(:order_with_totals, payment_state: "credit_owed", distributor:) }
    let(:order2) { create(:order_with_totals, payment_state: "credit_owed", distributor:) }
    let(:distributor) { create(:distributor_enterprise) }
    let(:service_response) { instance_double(Orders::CustomerCreditService::Response) }
    let(:format) { :turbo_stream }

    before do
      sign_in distributor.owner
    end

    it "credits the given orders" do
      credit_service_mock = mock_credit_service_for(orders: [order, order1, order2])

      allow(service_response).to receive(:failure?).and_return(false)
      expect(credit_service_mock).to receive(:refund).and_return(service_response).exactly(3).times

      post(
        "/admin/orders/bulk_credit", params: { bulk_ids: [order.id, order1.id, order2.id], format: }
      )

      expect(response).to have_http_status :ok
      expect(response.body).to include("order_#{order.id}", "order_#{order1.id}",
                                       "order_#{order2.id}")
    end

    context "when refund fails" do
      it "displays an error" do
        credit_service_mock = mock_credit_service_for(orders: [order, order1])

        allow(service_response).to receive(:failure?).and_return(true)
        allow(service_response).to receive(:message).and_return("No credit owed")
        expect(credit_service_mock).to receive(:refund).and_return(service_response)
          .exactly(2).times

        post("/admin/orders/bulk_credit", params: { bulk_ids: [order.id, order1.id], format: })

        expect(response).to have_http_status :ok
        # For some reason the flashes template is not rendered, but we can check the "flashes"
        # target is included twice
        expect(response.body).to include("flashes").twice
        # flash[:error] only include the last entry, it lets us check the error message
        # is correctly formated
        expect(flash[:error]).to end_with "could not be credited : No credit owed"
        expect(response.body).not_to include("order_#{order.id}", "order_#{order1.id}")
      end
    end

    context "with a non editable order" do
      let(:other_order) {
        create(:order_with_totals, payment_state: "credit_owed",
                                   distributor: create(:distributor_enterprise))
      }

      it "doesn't refund the order" do
        expect(Orders::CustomerCreditService).not_to receive(:new).with(other_order)

        post(
          "/admin/orders/bulk_credit", params: { bulk_ids: [other_order], format: }
        )

        expect(response).to have_http_status :ok
        expect(response.body).not_to include("order_#{other_order.id}")
      end
    end
  end

  def mock_credit_service_for(orders: [])
    credit_service_mock = instance_double(Orders::CustomerCreditService)
    orders.each do |order|
      expect(Orders::CustomerCreditService).to receive(:new).with(order).and_return(
        credit_service_mock
      )
    end

    credit_service_mock
  end
end
