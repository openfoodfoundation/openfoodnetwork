# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PaymentGateways::TwintController do
  include StripeStubs

  let!(:distributor) { create(:distributor_enterprise, with_payment_and_shipping: true) }
  let!(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
  let!(:order) { create(:order_with_totals, distributor:, order_cycle:) }
  let(:exchange) { order_cycle.exchanges.to_enterprises(distributor).outgoing.first }
  let!(:payment) { create(:payment, order:, state: "completed") }

  before do
    exchange.variants << order.line_items.first.variant
    allow(controller).to receive(:current_order).and_return(order)
    allow(controller).to receive(:order_failed_route).and_return("/order_failed")
  end

  describe "#confirm" do
    context "when the payment intent is valid" do
      before do
        allow(controller).to receive(:valid_payment_intent?).and_return(true)
        allow(controller).to receive(:validate_stock).and_return(true)
        allow(controller).to receive(:params).and_return({ "redirect_status" => "succeeded",
                                                           "payment_intent" => "pi_123" })

        workflow_service = instance_double("Orders::WorkflowService")
        allow(Orders::WorkflowService).to receive(:new).with(order).and_return(workflow_service)
        allow(workflow_service).to receive(:next).and_return(true)
        allow(order).to receive(:complete?).and_return(true)
      end

      it "calls validate_stock and redirects to the confirmation page" do
        expect(controller).to receive(:validate_stock)

        get :confirm, params: { payment_intent: "pi_123", redirect_status: "succeeded" }

        expect(response).to redirect_to order_path(order, order_token: order.token)
      end
      context "when the order cycle has closed" do
        it "redirects to shopfront with message if order cycle is expired" do
          allow(controller).to receive(:current_distributor).and_return(distributor)
          expect(controller).to receive(:current_order_cycle).and_return(order_cycle)
          expect(controller).to receive(:current_order).and_return(order).at_least(:once)
          expect(order_cycle).to receive(:closed?).and_return(true)
          expect(order).to receive(:empty!)
          expect(order).to receive(:assign_order_cycle!).with(nil)

          get :confirm, params: { payment_intent: "pi_123" }

          expect(response).to redirect_to shop_url
          expect(flash[:info]).to eq(
            "The order cycle you've selected has just closed. Please try again!"
          )
        end
      end
    end
    context "when the payment intent is invalid" do
      before do
        allow(controller).to receive(:valid_payment_intent?).and_return(false)
        allow(controller).to receive(:params).and_return({ "redirect_status" => "failed",
                                                           "payment_intent" => "pi_123" })
      end

      it "does not call validate_stock and redirects to the failed order route" do
        expect(controller).not_to receive(:validate_stock)

        get :confirm, params: { payment_intent: "pi_123", redirect_status: "failed" }

        expect(response).to redirect_to "/order_failed"
      end
    end
  end

  describe "#validate_stock" do
    before do
      allow(controller).to receive(:sufficient_stock?).and_return(sufficient_stock)
      allow(controller).to receive(:cancel_incomplete_payments)
      allow(controller).to receive(:handle_insufficient_stock)
    end

    context "when stock is sufficient" do
      let(:sufficient_stock) { true }

      it "does not cancel payments or handle insufficient stock" do
        controller.__send__(:validate_stock)

        expect(controller).not_to have_received(:cancel_incomplete_payments)
        expect(controller).not_to have_received(:handle_insufficient_stock)
      end
    end

    context "when stock is insufficient" do
      let(:sufficient_stock) { false }

      it "cancels incomplete payments and handles insufficient stock" do
        controller.__send__(:validate_stock)

        expect(controller).to have_received(:cancel_incomplete_payments)
        expect(controller).to have_received(:handle_insufficient_stock)
      end
    end
  end

  describe "#valid_payment_intent?" do
    before do
      allow(controller).to receive(:params).and_return(params)
      allow(controller).to receive(:order_and_payment_valid?).and_return(order_and_payment_valid)
    end

    context "when the payment intent starts with 'pi_' and order and payment are valid" do
      let(:params) { { "payment_intent" => "pi_123" } }
      let(:order_and_payment_valid) { true }

      it "returns true" do
        expect(controller.__send__(:valid_payment_intent?)).to be true
      end
    end

    context "when the payment intent does not start with 'pi_'" do
      let(:params) { { "payment_intent" => "invalid_123" } }
      let(:order_and_payment_valid) { true }

      it "returns false" do
        expect(controller.__send__(:valid_payment_intent?)).to be false
      end
    end

    context "when order and payment are not valid" do
      let(:params) { { "payment_intent" => "pi_123" } }
      let(:order_and_payment_valid) { false }

      it "returns false" do
        expect(controller.__send__(:valid_payment_intent?)).to be false
      end
    end
  end

  describe "#order_and_payment_valid?" do
    let(:last_payment) { instance_double("Spree::Payment", response_code: "pi_123") }

    before do
      controller.instance_variable_set(:@order, order)
      allow(order).to receive(:state).and_return(order_state)
      allow(controller).to receive(:last_payment).and_return(last_payment)
      allow(controller).to receive(:params).and_return(params)
    end

    context "when the order is 'payment' state and last payment matches the payment intent" do
      let(:order_state) { "payment" }
      let(:params) { { "payment_intent" => "pi_123" } }

      it "returns true" do
        expect(controller.__send__(:order_and_payment_valid?)).to be true
      end
    end

    context "when the order is 'confirmation' and last payment matches the payment intent" do
      let(:order_state) { "confirmation" }
      let(:params) { { "payment_intent" => "pi_123" } }

      it "returns true" do
        expect(controller.__send__(:order_and_payment_valid?)).to be true
      end
    end

    context "when the order is not in 'payment' or 'confirmation' state" do
      let(:order_state) { "cart" }
      let(:params) { { "payment_intent" => "pi_123" } }

      it "returns false" do
        expect(controller.__send__(:order_and_payment_valid?)).to be false
      end
    end

    context "when the last payment does not match the payment intent" do
      let(:order_state) { "payment" }
      let(:params) { { "payment_intent" => "pi_456" } }

      it "returns false" do
        expect(controller.__send__(:order_and_payment_valid?)).to be false
      end
    end

    context "when there is no last payment" do
      let(:order_state) { "payment" }
      let(:params) { { "payment_intent" => "pi_123" } }

      before do
        allow(controller).to receive(:last_payment).and_return(nil)
      end

      it "returns false" do
        expect(controller.__send__(:order_and_payment_valid?)).to be false
      end
    end
  end

  describe "#last_payment" do
    let(:find_payment_service) { instance_double("Orders::FindPaymentService") }
    let(:last_payment) { instance_double("Spree::Payment") }

    before do
      controller.instance_variable_set(:@order, order)

      allow(Orders::FindPaymentService)
        .to receive(:new)
        .with(order)
        .and_return(find_payment_service)
      allow(find_payment_service).to receive(:last_payment).and_return(last_payment)
    end

    it "returns the last payment for the order" do
      expect(controller.__send__(:last_payment)).to eq(last_payment)
      expect(Orders::FindPaymentService).to have_received(:new).with(order)
      expect(find_payment_service).to have_received(:last_payment)
    end
  end

  describe "#cancel_incomplete_payments" do
    let(:payment1) { instance_double("Spree::Payment") }
    let(:payment2) { instance_double("Spree::Payment") }
    let(:adjustment1) { instance_double("Spree::Adjustment") }
    let(:adjustment2) { instance_double("Spree::Adjustment") }

    before do
      # Stub @order and its payments
      controller.instance_variable_set(:@order, order)
      allow(order).to receive_message_chain(:payments, :incomplete).and_return([payment1, payment2])

      # Stub methods on payments
      allow(payment1).to receive(:void_transaction!)
      allow(payment2).to receive(:void_transaction!)
      allow(payment1).to receive(:adjustment).and_return(adjustment1)
      allow(payment2).to receive(:adjustment).and_return(adjustment2)

      # Stub methods on adjustments
      allow(adjustment1).to receive(:update_columns)
      allow(adjustment2).to receive(:update_columns)
    end

    it "voids transactions, updates adjustments, and sets a flash notice" do
      controller.__send__(:cancel_incomplete_payments)

      # Verify void_transaction! is called on each payment
      expect(payment1).to have_received(:void_transaction!)
      expect(payment2).to have_received(:void_transaction!)

      # Verify adjustments are updated
      expect(adjustment1).to have_received(:update_columns).with(
        eligible: false, state: "finalized"
      )
      expect(adjustment2).to have_received(:update_columns).with(
        eligible: false, state: "finalized"
      )

      # Verify flash notice is set
      expect(flash[:notice]).to eq(
        I18n.t(
          "checkout.payment_cancelled_due_to_stock"
        )
      )
    end
  end
end
