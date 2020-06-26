require 'spec_helper'

module Spree
  describe Payment do

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
