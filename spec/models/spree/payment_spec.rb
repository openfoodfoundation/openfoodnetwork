require 'spec_helper'

module Spree
  describe Payment do
    describe "available actions" do
      context "for most gateways" do
        let(:payment) { create(:payment, source: create(:credit_card)) }

        it "can capture and void" do
          expect(payment.actions).to match_array %w(capture void)
        end

        describe "when a payment has been taken" do
          before do
            allow(payment).to receive(:state) { 'completed' }
            allow(payment).to receive(:order) { double(:order, payment_state: 'credit_owed') }
          end

          it "can void and credit" do
            expect(payment.actions).to match_array %w(void credit)
          end
        end
      end

      context "for Pin Payments" do
        let(:d) { create(:distributor_enterprise) }
        let(:pin) { Gateway::Pin.create! name: 'pin', distributor_ids: [d.id] }
        let(:payment) { create(:payment, source: create(:credit_card), payment_method: pin) }

        it "does not void" do
          expect(payment.actions).not_to include 'void'
        end

        describe "when a payment has been taken" do
          before do
            allow(payment).to receive(:state) { 'completed' }
            allow(payment).to receive(:order) { double(:order, payment_state: 'credit_owed') }
          end

          it "can refund instead of crediting" do
            expect(payment.actions).not_to include 'credit'
            expect(payment.actions).to     include 'refund'
          end
        end
      end
    end

    describe "refunding" do
      let(:payment) { create(:payment) }
      let(:success) { double(success?: true, authorization: 'abc123') }
      let(:failure) { double(success?: false) }

      it "always checks the environment" do
        allow(payment.payment_method).to receive(:refund) { success }
        expect(payment).to receive(:check_environment)
        payment.refund!
      end

      describe "calculating refund amount" do
        it "returns the parameter amount when given" do
          expect(payment.send(:calculate_refund_amount, 123)).to be === 123.0
        end

        it "refunds up to the value of the payment when the outstanding balance is larger" do
          allow(payment).to receive(:credit_allowed) { 123 }
          allow(payment).to receive(:order) { double(:order, outstanding_balance: 1000) }
          expect(payment.send(:calculate_refund_amount)).to eq(123)
        end

        it "refunds up to the outstanding balance of the order when the payment is larger" do
          allow(payment).to receive(:credit_allowed) { 1000 }
          allow(payment).to receive(:order) { double(:order, outstanding_balance: 123) }
          expect(payment.send(:calculate_refund_amount)).to eq(123)
        end
      end

      describe "performing refunds" do
        before do
          allow(payment).to receive(:calculate_refund_amount) { 123 }
          expect(payment.payment_method).to receive(:refund).and_return(success)
        end

        it "performs the refund without payment profiles" do
          allow(payment.payment_method).to receive(:payment_profiles_supported?) { false }
          payment.refund!
        end

        it "performs the refund with payment profiles" do
          allow(payment.payment_method).to receive(:payment_profiles_supported?) { true }
          payment.refund!
        end
      end

      it "records the response" do
        allow(payment).to receive(:calculate_refund_amount) { 123 }
        allow(payment.payment_method).to receive(:refund).and_return(success)
        expect(payment).to receive(:record_response).with(success)
        payment.refund!
      end

      it "records a payment on success" do
        allow(payment).to receive(:calculate_refund_amount) { 123 }
        allow(payment.payment_method).to receive(:refund).and_return(success)
        allow(payment).to receive(:record_response)

        expect do
          payment.refund!
        end.to change(Payment, :count).by(1)

        p = Payment.last
        expect(p.order).to eq(payment.order)
        expect(p.source).to eq(payment)
        expect(p.payment_method).to eq(payment.payment_method)
        expect(p.amount).to eq(-123)
        expect(p.response_code).to eq(success.authorization)
        expect(p.state).to eq('completed')
      end

      it "logs the error on failure" do
        allow(payment).to receive(:calculate_refund_amount) { 123 }
        allow(payment.payment_method).to receive(:refund).and_return(failure)
        allow(payment).to receive(:record_response)
        expect(payment).to receive(:gateway_error).with(failure)
        payment.refund!
      end
    end

    describe "applying transaction fees" do
      let!(:order) { create(:order) }
      let!(:line_item) { create(:line_item, order: order, quantity: 3, price: 5.00) }

      before do
        order.reload.update!
      end

      context "when order-based calculator" do
        let!(:shop) { create(:enterprise) }
        let!(:payment_method) { create(:payment_method, calculator: calculator) }

        let!(:calculator) do
          Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10)
        end

        context "when order complete and inventory tracking enabled" do
          let!(:order) { create(:completed_order_with_totals, distributor: shop) }
          let!(:variant) { order.line_items.first.variant }
          let!(:inventory_item) { create(:inventory_item, enterprise: shop, variant: variant) }

          it "creates adjustment" do
            payment = create(:payment, order: order, payment_method: payment_method,
                                       amount: order.total)
            expect(payment.adjustment).to be_present
            expect(payment.adjustment.amount).not_to eq(0)
          end
        end
      end

      context "to Stripe payments" do
        let(:shop) { create(:enterprise) }
        let(:payment_method) { create(:stripe_payment_method, distributor_ids: [create(:distributor_enterprise).id], preferred_enterprise_id: shop.id) }
        let(:payment) { create(:payment, order: order, payment_method: payment_method, amount: order.total) }
        let(:calculator) { Spree::Calculator::FlatPercentItemTotal.new(preferred_flat_percent: 10) }

        before do
          payment_method.calculator = calculator
          payment_method.save!

          allow(order).to receive(:pending_payments) { [payment] }
        end

        context "when the payment fails" do
          let(:failed_response) { ActiveMerchant::Billing::Response.new(false, "This is an error message") }

          before do
            allow(payment_method).to receive(:purchase) { failed_response }
          end

          it "makes the transaction fee ineligible and finalizes it" do
            # Decided to wrap the save process in order.process_payments!
            # since that is the context it is usually performed in
            order.process_payments!
            expect(order.payments.count).to eq 1
            expect(order.payments).to include payment
            expect(payment.state).to eq "failed"
            expect(payment.adjustment.eligible?).to be false
            expect(payment.adjustment.finalized?).to be true
            expect(order.adjustments.payment_fee.count).to eq 1
            expect(order.adjustments.payment_fee.eligible).to_not include payment.adjustment
          end
        end

        context "when the payment information is invalid" do
          before do
            allow(payment_method).to receive(:supports?) { false }
          end

          it "makes the transaction fee ineligible and finalizes it" do
            # Decided to wrap the save process in order.process_payments!
            # since that is the context it is usually performed in
            order.process_payments!
            expect(order.payments.count).to eq 1
            expect(order.payments).to include payment
            expect(payment.state).to eq "invalid"
            expect(payment.adjustment.eligible?).to be false
            expect(payment.adjustment.finalized?).to be true
            expect(order.adjustments.payment_fee.count).to eq 1
            expect(order.adjustments.payment_fee.eligible).to_not include payment.adjustment
          end
        end

        context "when the payment is processed successfully" do
          let(:successful_response) { ActiveMerchant::Billing::Response.new(true, "Yay!") }

          before do
            allow(payment_method).to receive(:purchase) { successful_response }
          end

          it "creates an appropriate adjustment" do
            # Decided to wrap the save process in order.process_payments!
            # since that is the context it is usually performed in
            order.process_payments!
            expect(order.payments.count).to eq 1
            expect(order.payments).to include payment
            expect(payment.state).to eq "completed"
            expect(payment.adjustment.eligible?).to be true
            expect(order.adjustments.payment_fee.count).to eq 1
            expect(order.adjustments.payment_fee.eligible).to include payment.adjustment
            expect(payment.adjustment.amount).to eq 1.5
          end
        end
      end
    end

    context "extends LocalizedNumber" do
      it_behaves_like "a model using the LocalizedNumber module", [:amount]
    end
  end
end
