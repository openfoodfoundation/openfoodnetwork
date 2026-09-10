# frozen_string_literal: true

RSpec.describe Orders::FindPaymentService do
  subject(:finder) { described_class.new(order) }
  let(:order) { create(:order_with_distributor) }

  describe "#last_pending_payment" do
    context "when order has several non pending payments" do
      let!(:failed_payment) { create(:payment, order:, state: 'failed') }
      let!(:complete_payment) { create(:payment, :completed, order:) }

      it "returns nil" do
        expect(finder.last_pending_payment).to be nil
      end
    end

    context "when order has a pending payment and a non pending payment" do
      let!(:processing_payment) { create(:payment, order:, state: 'processing') }
      let!(:failed_payment) { create(:payment, order:, state: 'failed') }

      it "returns the pending payment" do
        # a payment in the processing state is a pending payment
        expect(finder.last_pending_payment).to eq processing_payment
      end

      context "and an extra last pending payment" do
        let!(:pending_payment) { create(:payment, order:, state: 'pending') }

        it "returns the pending payment" do
          expect(finder.last_pending_payment).to eq pending_payment
        end
      end
    end
  end

  describe "#last_pending_payment_excluding_credit" do
    let!(:credit_payment) {
      create(:payment, order:, payment_method: Spree::PaymentMethod.customer_credit,
                       skip_source_validation: true, source: nil)
    }

    context "when the order only has a customer credit payment" do
      it "returns nil" do
        expect(finder.last_pending_payment_excluding_credit).to be nil
      end
    end

    context "when the customer also chose a payment method" do
      let!(:chosen_payment) { create(:payment, order:) }

      it "returns the payment the customer chose" do
        expect(finder.last_pending_payment_excluding_credit).to eq chosen_payment
      end
    end
  end

  describe "#last_payment" do
    context "when order has several non pending payments" do
      let!(:failed_payment) { create(:payment, order:, state: 'failed') }
      let!(:complete_payment) { create(:payment, :completed, order:) }

      it "returns the last payment" do
        expect(finder.last_payment).to eq complete_payment
      end
    end

    context "when order has a pending payment and a non pending payment" do
      let!(:processing_payment) { create(:payment, order:, state: 'processing') }
      let!(:failed_payment) { create(:payment, order:, state: 'failed') }

      it "returns the last payment" do
        expect(finder.last_payment).to eq failed_payment
      end

      context "and an extra last pending payment" do
        let!(:pending_payment) { create(:payment, order:, state: 'pending') }

        it "returns the last payment" do
          expect(finder.last_payment).to eq pending_payment
        end
      end
    end
  end

  describe "#last_customer_credit" do
    let!(:credit_payment) {
      create(:payment, order:, state: 'processing',
                       payment_method: Spree::PaymentMethod.customer_credit)
    }
    let!(:last_credit_payment) {
      create(:payment, order:, state: 'processing',
                       payment_method: Spree::PaymentMethod.customer_credit)
    }

    it "returns the last customer credit" do
      expect(finder.last_customer_credit).to eq(last_credit_payment)
    end

    context "with other payments" do
      let!(:complete_credit_paymnet) {
        create(:payment, order:, state: 'completed',
                         payment_method: Spree::PaymentMethod.customer_credit)
      }
      let!(:processing_payment) { create(:payment, order:, state: 'processing') }
      let!(:failed_payment) { create(:payment, order:, state: 'failed') }

      it "returns the last customer credit" do
        expect(finder.last_customer_credit).to eq(last_credit_payment)
      end
    end

    context "when the only pending payment has no associated payment method" do
      let(:credit_payment) { nil }
      let(:last_credit_payment) { nil }
      let!(:payment_without_method) {
        create(:payment, order:, state: "processing", payment_method: nil)
      }

      it "returns nil" do
        expect(finder.last_customer_credit).to be_nil
      end
    end
  end

  describe "#last_pending_paypal_payment" do
    let!(:payment) { create(:payment, order:, state: "checkout") }
    let(:payment_method) { create(:paypal_payment_method) }
    let(:paypal_payment) {
      create(:payment, order:, state: 'processing', payment_method:)
    }
    let(:last_paypal_payment) {
      create(:payment, order:, state: 'processing', payment_method:)
    }

    it "returns the last pending paypal payment" do
      paypal_payment
      last_paypal_payment

      expect(finder.last_pending_paypal_payment).to eq(last_paypal_payment)
    end

    context "with other payments" do
      let(:completed_paypal_payment) {
        create(:payment, order:, state: "completed", payment_method: )
      }
      let(:processing_payment) { create(:payment, order:, state: "processing") }
      let(:failed_payment) { create(:payment, order:, state: "failed") }

      it "returns the last pending paypal payment" do
        paypal_payment
        last_paypal_payment
        completed_paypal_payment
        processing_payment
        failed_payment

        expect(finder.last_pending_paypal_payment).to eq(last_paypal_payment)
      end
    end

    context "when no paypal payment method" do
      it "returns nil" do
        expect(finder.last_pending_paypal_payment).to be_nil
      end
    end

    context "when a pending payment has no associated payment method" do
      let!(:payment_without_method) {
        create(:payment, order:, state: "processing", payment_method: nil)
      }

      it "returns nil" do
        expect(finder.last_pending_paypal_payment).to be_nil
      end
    end
  end
end
