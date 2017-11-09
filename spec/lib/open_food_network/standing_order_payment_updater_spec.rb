require 'open_food_network/standing_order_payment_updater'

module OpenFoodNetwork
  describe StandingOrderPaymentUpdater do
    let(:order) { create(:order) }
    let(:updater) { OpenFoodNetwork::StandingOrderPaymentUpdater.new(order) }

    describe "#payment" do
      context "when only one payment exists on the order" do
        let!(:payment) { create(:payment, order: order) }

        context "where the payment is in the 'checkout' state" do
          it { expect(updater.send(:payment)).to eq payment }
        end

        context "where the payment is in some other state" do
          before { payment.update_attribute(:state, 'pending') }
          it { expect(updater.send(:payment)).to be nil }
        end
      end

      context "when more that one payment exists on the order" do
        let!(:payment1) { create(:payment, order: order) }
        let!(:payment2) { create(:payment, order: order) }

        context "where more than one payment is in the 'checkout' state" do
          it { expect(updater.send(:payment)).to eq payment1 }
        end

        context "where only one payment is in the 'checkout' state" do
          before { payment1.update_attribute(:state, 'pending') }
          it { expect(updater.send(:payment)).to eq payment2 }
        end

        context "where no payments are in the 'checkout' state" do
          before do
            payment1.update_attribute(:state, 'pending')
            payment2.update_attribute(:state, 'pending')
          end

          it { expect(updater.send(:payment)).to be nil }
        end
      end
    end

    describe "#update!" do
      let!(:payment){ create(:payment, amount: 10) }

      context "when no payment is present" do
        before { allow(updater).to receive(:payment) { nil } }
        it { expect(updater.update!).to be nil }
      end

      context "when a payment is present" do
        before { allow(updater).to receive(:payment) { payment } }

        context "when the payment total doesn't match the outstanding balance on the order" do
          before { allow(order).to receive(:outstanding_balance) { 5 } }
          it "updates the payment total to reflect the outstanding balance" do
            expect{updater.update!}.to change(payment, :amount).from(10).to(5)
          end
        end

        context "when the payment total matches the outstanding balance on the order" do
          before { allow(order).to receive(:outstanding_balance) { 10 } }

          it "does nothing" do
            expect{updater.update!}.to_not change(payment, :amount).from(10)
          end
        end
      end
    end
  end
end
