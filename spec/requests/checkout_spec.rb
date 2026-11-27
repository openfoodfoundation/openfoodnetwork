# frozen_string_literal: true

# We are moving to request spec, this file only covers payment step specs, see
# spec/controllers/checkout_controller_spec.rb for the any other spec.
# Use this file instead of updating spec/controllers/checkout_controller_spec.rb when possible.
#
RSpec.describe CheckoutController do
  include_context "session helper"

  let(:user) { order.user }
  let(:address) { create(:address) }
  let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor]) }
  let(:exchange) { order_cycle.exchanges.outgoing.first }
  let(:order) {
    create(:order_with_line_items, line_items_count: 1, distributor:, order_cycle:)
  }
  let(:shipping_method) { distributor.shipping_methods.first }
  let(:payment_method) { distributor.payment_methods.first }

  before do
    exchange.variants << order.line_items.first.variant
    session_hash[:order_id] = order.id
    sign_in user
  end

  describe "PUT /checkout/:step" do
    context "with details step" do
      let(:pickup) do
        create(:shipping_method, distributors: [distributor], require_ship_address: false)
      end

      context "when a pickup shipping method is submitted without billing address" do
        let(:params) do
          { step: "details", shipping_method_id: pickup.id, order: { email: user.email } }
        end

        before { order.update_columns(bill_address_id: nil, ship_address_id: nil) }

        it "returns 422 and some feedback instead of raising" do
          put checkout_update_path(params)

          expect(response).to have_http_status :unprocessable_entity
          expect(flash[:error]).to match "Saving failed, please update the highlighted fields."
        end
      end
    end

    context "with payment step" do
      let(:checkout_params) { {} }
      let(:params) { { step: }.merge(checkout_params) }
      let(:step) { "payment" }

      before do
        order.bill_address = address
        order.ship_address = address
        order.select_shipping_method shipping_method.id
        Orders::WorkflowService.new(order).advance_to_payment
      end

      context "with incomplete data" do
        let(:checkout_params) { { order: { email: user.email } } }

        it "returns 422 and some feedback" do
          put checkout_update_path(params)

          expect(response).to have_http_status :unprocessable_entity
          expect(flash[:error]).to match "Saving failed, please update the highlighted fields."
          expect(order.reload.state).to eq "payment"
        end
      end

      context "with complete data" do
        let(:checkout_params) do
          {
            order: {
              payments_attributes: [
                { payment_method_id: payment_method.id }
              ]
            }
          }
        end

        it "updates and redirects to summary step" do
          put checkout_update_path(params)

          expect(response).to redirect_to checkout_step_path(:summary)
          expect(order.reload.state).to eq "confirmation"
        end

        describe "with a voucher" do
          let(:voucher) { create(:voucher_flat_rate, enterprise: distributor) }

          before do
            voucher.create_adjustment(voucher.code, order)
          end

          # so we need to recalculate voucher to account for payment fees
          it "recalculates the voucher adjustment" do
            service = mock_voucher_adjustment_service
            expect(service).to receive(:update)

            put checkout_update_path(params)

            expect(response).to redirect_to checkout_step_path(:summary)
          end
        end

        context "with insufficient stock" do
          it "redirects to details page" do
            check_stock_service_mock = instance_double(Orders::CheckStockService)
            allow(Orders::CheckStockService).to receive(:new).with(order: order).and_return(
              check_stock_service_mock
            )

            expect(check_stock_service_mock).to receive(:sufficient_stock?).and_return(false)

            put checkout_update_path(params)

            expect_cable_ready_redirect(response)
          end
        end

        context "with existing invalid payments" do
          let(:invalid_payments) {
            [
              create(:payment, state: :invalid),
              create(:payment, state: :invalid),
            ]
          }

          before do
            order.payments = invalid_payments
          end

          it "deletes invalid payments" do
            # Delete the 2 invalid payment and create a new one
            expect{
              put checkout_update_path(params)
            }.to change { order.reload.payments.count }.from(2).to(1)
          end
        end

        context "with different payment method previously chosen" do
          let(:other_payment_method) { build(:payment_method, distributors: [distributor]) }
          let(:other_payment) {
            build(:payment, amount: order.total, payment_method: other_payment_method)
          }

          before do
            order.payments = [other_payment]
          end

          context "and order is in an earlier state" do
            # This revealed obscure bug #12693. If you progress to order summary, go back to payment
            # method, then open delivery details in a new tab (or hover over the link with Turbo
            # enabled), then submit new payment details, this happens.

            before do
              order.back_to_address
            end

            it "deletes invalid (old) payments" do
              put checkout_update_path(params)

              order.payments.reload
              expect(order.payments).not_to include other_payment
            end
          end
        end
      end

      context "with no payment source" do
        let(:checkout_params) do
          {
            order: {
              payments_attributes: [
                {
                  payment_method_id:,
                  source_attributes: {
                    first_name: "Jane",
                    last_name: "Doe",
                    month: "",
                    year: "",
                    cc_type: "",
                    last_digits: "",
                    gateway_payment_profile_id: ""
                  }
                }
              ]
            },
            commit: "Next - Order Summary"
          }
        end

        context "with a cash/check payment method" do
          let!(:payment_method_id) { payment_method.id }

          it "updates and redirects to summary step" do
            put checkout_update_path(params)

            expect(response).to have_http_status :found
            expect(response).to redirect_to checkout_step_path(:summary)
            expect(order.reload.state).to eq "confirmation"
          end
        end

        context "with a StripeSCA payment method" do
          let(:stripe_payment_method) {
            create(:stripe_sca_payment_method, distributor_ids: [distributor.id],
                                               environment: Rails.env)
          }
          let!(:payment_method_id) { stripe_payment_method.id }

          it "updates and redirects to summary step" do
            put checkout_update_path(params)

            expect(response).to have_http_status :unprocessable_entity
            expect(flash[:error]).to match "Saving failed, please update the highlighted fields."
            expect(order.reload.state).to eq "payment"
          end
        end
      end

      context "with payment fees" do
        let(:payment_method_with_fee) do
          create(:payment_method, :flat_rate, amount: "1.23", distributors: [distributor])
        end
        let(:checkout_params) do
          {
            order: {
              payments_attributes: [
                { payment_method_id: payment_method_with_fee.id }
              ]
            }
          }
        end

        it "applies the fee and updates the order total" do
          put checkout_update_path(params)

          expect(response).to redirect_to checkout_step_path(:summary)

          order.reload

          expect(order.state).to eq "confirmation"
          expect(order.payments.first.adjustment.amount).to eq 1.23
          expect(order.payments.first.amount).to eq order.item_total + order.adjustment_total
          expect(order.adjustment_total).to eq 1.23
          expect(order.total).to eq order.item_total + order.adjustment_total
        end
      end

      context "with a zero-priced order" do
        let(:params) do
          { step: "payment", order: { payments_attributes: [{ amount: 0 }] } }
        end

        before do
          order.line_items.first.update(price: 0)
          order.update_totals_and_states
        end

        it "allows proceeding to confirmation" do
          put checkout_update_path(params)

          expect(response).to redirect_to checkout_step_path(:summary)
          expect(order.reload.state).to eq "confirmation"
          expect(order.payments.count).to eq 1
          expect(order.payments.first.amount).to eq 0
        end
      end

      context "with a saved credit card" do
        let!(:saved_card) { create(:stored_credit_card, user:) }
        let(:checkout_params) do
          {
            order: {
              payments_attributes: [
                { payment_method_id: payment_method.id }
              ]
            },
            existing_card_id: saved_card.id
          }
        end

        it "updates and redirects to summary step" do
          put checkout_update_path(params)

          expect(response).to redirect_to checkout_step_path(:summary)
          expect(order.reload.state).to eq "confirmation"
          expect(order.payments.first.source.id).to eq saved_card.id
        end
      end

      context "with an order paid with customer credit" do
        before do
          ## Add payment with credit
          payment = order.payments.create!(
            amount: order.total,
            payment_method: Spree::PaymentMethod.customer_credit,
            state: "checkout"
          )
        end

        it "allows proceeding to confirmation" do
          put checkout_update_path(params)

          expect(response).to redirect_to checkout_step_path(:summary)
          expect(order.reload.state).to eq "confirmation"
        end
      end
    end
  end

  def mock_voucher_adjustment_service
    voucher_adjustment_service = instance_double(VoucherAdjustmentsService)
    allow(VoucherAdjustmentsService).to receive(:new).and_return(voucher_adjustment_service)

    voucher_adjustment_service
  end

  def expect_cable_ready_redirect(response)
    expect(response.parsed_body).to eq(
      [{ "url" => "/checkout/details", "operation" => "redirectTo" }].to_json
    )
  end
end
