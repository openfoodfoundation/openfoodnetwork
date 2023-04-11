# frozen_string_literal: true

require 'spec_helper'

describe SplitCheckoutController, type: :controller do
  let(:user) { order.user }
  let(:address) { create(:address) }
  let(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let(:order_cycle) { create(:order_cycle, distributors: [distributor]) }
  let(:exchange) { order_cycle.exchanges.outgoing.first }
  let(:order) {
    create(:order_with_line_items, line_items_count: 1, distributor: distributor,
                                   order_cycle: order_cycle)
  }
  let(:payment_method) { distributor.payment_methods.first }
  let(:shipping_method) { distributor.shipping_methods.first }

  before do
    Flipper.enable(:split_checkout)

    exchange.variants << order.line_items.first.variant
    allow(controller).to receive(:current_order) { order }
    allow(controller).to receive(:spree_current_user) { user }
  end

  describe "#edit" do
    it "renders the checkout" do
      get :edit, params: { step: "details" }
      expect(response.status).to eq 200
    end

    it "redirects to current step if no step is given" do
      get :edit
      expect(response).to redirect_to checkout_step_path(:details)
    end

    context "when line items in the cart are not valid" do
      before { allow(controller).to receive(:valid_order_line_items?) { false } }

      it "redirects to cart" do
        get :edit
        expect(response).to redirect_to cart_path
      end
    end

    context "when the given `step` params is inconsistent with the current order state" do
      context "when order state is `cart`" do
        before do
          order.update!(state: "cart")
        end

        it "redirects to the valid step if params is `payment`" do
          get :edit, params: { step: "payment" }
          expect(response).to redirect_to checkout_step_path(:details)
        end
        it "redirects to the valid step if params is `summary`" do
          get :edit, params: { step: "summary" }
          expect(response).to redirect_to checkout_step_path(:details)
        end
      end

      context "when order state is `payment`" do
        before do
          order.update!(state: "payment")
        end

        it "redirects to the valid step if params is `summary`" do
          get :edit, params: { step: "summary" }
          expect(response).to redirect_to checkout_step_path(:payment)
        end
      end
    end
  end

  describe "#update" do
    let(:checkout_params) { {} }
    let(:params) { { step: step }.merge(checkout_params) }

    context "details step" do
      let(:step) { "details" }

      context "with incomplete data" do
        let(:checkout_params) { { order: { email: user.email } } }

        it "returns 422 and some feedback" do
          put :update, params: params

          expect(response.status).to eq 422
          expect(flash[:error]).to match "Saving failed, please update the highlighted fields."
          expect(order.reload.state).to eq "cart"
        end
      end

      context "with complete data" do
        let(:checkout_params) do
          {
            order: {
              email: user.email,
              bill_address_attributes: address.to_param,
              ship_address_attributes: address.to_param
            },
            shipping_method_id: shipping_method.id
          }
        end

        it "updates and redirects to payment step" do
          put :update, params: params

          expect(response).to redirect_to checkout_step_path(:payment)
          expect(order.reload.state).to eq "payment"
        end

        describe "saving default addresses" do
          it "doesn't update default bill address on user" do
            expect {
              put :update, params: params.merge(order: { save_bill_address: "0" })
            }.to_not change {
              order.user.reload.bill_address
            }
          end

          it "updates default bill address on user and customer" do
            put :update, params: params.merge(order: { save_bill_address: "1" })

            expect(order.customer.bill_address).to eq(order.bill_address)
            expect(order.user.bill_address).to eq(order.bill_address)
          end

          it "doesn't update default ship address on user" do
            expect {
              put :update, params: params.merge(order: { save_ship_address: "0" })
            }.to_not change {
              order.user.reload.ship_address
            }
          end

          it "updates default ship address on user and customer" do
            put :update, params: params.merge(order: { save_ship_address: "1" })

            expect(order.customer.ship_address).to eq(order.ship_address)
            expect(order.user.ship_address).to eq(order.ship_address)
          end
        end
      end
    end

    context "payment step" do
      let(:step) { "payment" }

      before do
        order.bill_address = address
        order.ship_address = address
        order.select_shipping_method shipping_method.id
        OrderWorkflow.new(order).advance_to_payment
      end

      context "with incomplete data" do
        let(:checkout_params) { { order: { email: user.email } } }

        it "returns 422 and some feedback" do
          put :update, params: params

          expect(response.status).to eq 422
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

        it "updates and redirects to payment step" do
          put :update, params: params

          expect(response).to redirect_to checkout_step_path(:summary)
          expect(order.reload.state).to eq "confirmation"
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
          put :update, params: params

          expect(response).to redirect_to checkout_step_path(:summary)

          order.reload

          expect(order.state).to eq "confirmation"
          expect(order.payments.first.adjustment.amount).to eq 1.23
          expect(order.payments.first.amount).to eq order.item_total + order.adjustment_total
          expect(order.adjustment_total).to eq 1.23
          expect(order.total).to eq order.item_total + order.adjustment_total
        end
      end

      context "with a saved credit card" do
        let!(:saved_card) { create(:stored_credit_card, user: user) }
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

        it "updates and redirects to payment step" do
          put :update, params: params

          expect(response).to redirect_to checkout_step_path(:summary)
          expect(order.reload.state).to eq "confirmation"
          expect(order.payments.first.source.id).to eq saved_card.id
        end
      end

      describe "Vouchers" do
        let(:voucher) { Voucher.create(code: 'some_code', enterprise: distributor) }

        describe "adding a voucher" do
          let(:checkout_params) do
            {
              order: {
                voucher_code: voucher.code
              }
            }
          end

          it "adds a voucher to the order" do
            put :update, params: params

            expect(response.status).to eq(200)
            expect(order.reload.vouchers.length).to eq(1)
          end

          context "when voucher doesn't exist" do
            let(:checkout_params) do
              {
                order: {
                  voucher_code: "non_voucher"
                }
              }
            end

            it "returns 422 and an error message" do
              put :update, params: params

              expect(response.status).to eq 422
              expect(flash[:error]).to match "Voucher Not found"
            end
          end

          context "when adding fails" do
            it "returns 422 and an error message" do
              # Makes adding the voucher fails
              allow(voucher).to receive(:create_adjustment).and_return(nil)
              allow(Voucher).to receive(:find_by).and_return(voucher)

              put :update, params: params

              expect(response.status).to eq 422
              expect(flash[:error]).to match "There was an error while adding the voucher"
            end
          end
        end

        describe "removing a voucher" do
          it "removes the voucher" do
            adjustment = voucher.create_adjustment(voucher.code, order)

            delete :destroy, params: { adjustment_id: adjustment.id }

            expect(response.status).to eq(200)
            expect(order.reload.vouchers.length).to eq(0)
          end
        end
      end
    end

    context "summary step" do
      let(:step) { "summary" }

      before do
        order.bill_address = address
        order.ship_address = address
        order.select_shipping_method shipping_method.id
        OrderWorkflow.new(order).advance_to_payment

        order.payments << build(:payment, amount: order.total, payment_method: payment_method)
        order.next
      end

      describe "confirming the order" do
        it "completes the order and redirects to order confirmation" do
          put :update, params: params

          expect(response).to redirect_to order_path(order, order_token: order.token)
          expect(order.reload.state).to eq "complete"
        end
      end

      context "when accepting T&Cs is required" do
        before do
          allow(TermsOfService).to receive(:platform_terms_required?) { true }
        end

        describe "submitting without accepting the T&Cs" do
          let(:checkout_params) { {} }

          it "returns 422 and some feedback" do
            put :update, params: params

            expect(response.status).to eq 422
            expect(flash[:error]).to match "Saving failed, please update the highlighted fields."
            expect(order.reload.state).to eq "confirmation"
          end
        end

        describe "submitting and accepting the T&Cs" do
          let(:checkout_params) { { accept_terms: true } }

          it "completes the order and redirects to order confirmation" do
            put :update, params: params

            expect(response).to redirect_to order_path(order, order_token: order.token)
            expect(order.reload.state).to eq "complete"
          end
        end
      end

      context "when an external payment gateway is used" do
        before do
          expect(Checkout::PaymentMethodFetcher).
            to receive_message_chain(:new, :call) { payment_method }
          expect(payment_method).to receive(:external_gateway?) { true }
          expect(payment_method).to receive(:external_payment_url) { "https://example.com/pay" }
        end

        describe "confirming the order" do
          it "redirects to the payment gateway's URL" do
            put :update, params: params

            expect(response.body).to match("https://example.com/pay").and match("redirect")
            expect(order.reload.state).to eq "confirmation"
          end
        end
      end
    end
  end

  describe "running out of stock" do
    let(:order_cycle_distributed_variants) { double(:order_cycle_distributed_variants) }

    before do
      allow(controller).to receive(:current_order).and_return(order)
      allow(order).to receive(:distributor).and_return(distributor)
      order.update(order_cycle: order_cycle)

      allow(OrderCycleDistributedVariants).to receive(:new).and_return(
        order_cycle_distributed_variants
      )
    end

    shared_examples "handling stock issues" do |step|
      context "#{step} step" do
        let(:step) { step.to_s }

        it "redirects when some items are out of stock" do
          allow(order).to receive_message_chain(:insufficient_stock_lines, :empty?).and_return false

          get :edit
          expect(response).to redirect_to cart_path
        end

        it "redirects when some items are not available" do
          allow(order).to receive_message_chain(:insufficient_stock_lines, :empty?).and_return true
          expect(order_cycle_distributed_variants).to receive(
            :distributes_order_variants?
          ).with(order).and_return(false)

          get :edit
          expect(response).to redirect_to cart_path
        end
      end
    end

    it_behaves_like "handling stock issues", "details"
    it_behaves_like "handling stock issues", "payment"
    it_behaves_like "handling stock issues", "summary"
  end
end
