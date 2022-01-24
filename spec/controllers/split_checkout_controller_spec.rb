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
    allow(Flipper).to receive(:enabled?).with(:split_checkout) { true }
    allow(Flipper).to receive(:enabled?).with(:split_checkout, anything) { true }

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
          expect(flash[:error]).to eq "Saving failed, please update the highlighted fields."
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
          it "updates default bill address on user and customer" do
            put :update, params: params.merge({ order: { save_bill_address: true } })

            expect(order.customer.bill_address).to eq(order.bill_address)
            expect(order.user.bill_address).to eq(order.bill_address)
          end

          it "updates default ship address on user and customer" do
            put :update, params: params.merge({ order: { save_ship_address: true } })

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
          expect(flash[:error]).to eq "Saving failed, please update the highlighted fields."
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

          expect(response).to redirect_to order_path(order)
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
            expect(flash[:error]).to eq "Saving failed, please update the highlighted fields."
            expect(order.reload.state).to eq "confirmation"
          end
        end

        describe "submitting and accepting the T&Cs" do
          let(:checkout_params) { { accept_terms: true } }

          it "completes the order and redirects to order confirmation" do
            put :update, params: params

            expect(response).to redirect_to order_path(order)
            expect(order.reload.state).to eq "complete"
          end
        end
      end
    end
  end
end
