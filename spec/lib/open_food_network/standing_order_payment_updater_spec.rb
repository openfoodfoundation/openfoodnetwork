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

      context "when no pending payments are present" do
        let(:payment_method) { create(:payment_method) }
        let(:standing_order) { double(:standing_order, payment_method_id: payment_method.id) }

        before do
          allow(order).to receive(:pending_payments).once { [] }
          allow(order).to receive(:outstanding_balance) { 5 }
          allow(order).to receive(:standing_order) { standing_order }
        end

        it "creates a new payment on the order" do
          expect{updater.update!}.to change(Spree::Payment, :count).by(1)
          expect(order.payments.first.amount).to eq 5
        end
      end

      context "when a payment is present" do
        before { allow(order).to receive(:pending_payments).once { [payment] } }

        context "when a credit card is not required" do
          before do
            allow(updater).to receive(:card_required?) { false }
            expect(updater).to_not receive(:card_available?)
            expect(updater).to_not receive(:ensure_credit_card)
          end

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

        context "when a credit card is required" do
          before do
            expect(updater).to receive(:card_required?) { true }
          end

          context "and the payment source is not a credit card" do
            before { expect(updater).to receive(:card_set?) { false } }

            context "and no credit card is available on the standing order" do
              before { expect(updater).to receive(:ensure_credit_card) { false } }

              it "does not update the payment" do
                expect(payment).to_not receive(:update_attributes)
                updater.update!
              end
            end

            context "but a credit card is available on the standing order" do
              before { expect(updater).to receive(:ensure_credit_card) { true } }

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

          context "and the payment source is already a credit card" do
            before { expect(updater).to receive(:card_set?) { true } }

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

    describe "#ensure_credit_card" do
      let!(:payment) { create(:payment, source: nil) }
      before { allow(updater).to receive(:payment) { payment } }

      context "when no credit card is specified by the standing order" do
        before { allow(updater).to receive(:saved_credit_card) { nil } }

        it "returns false and down not update the payment source" do
          expect do
            expect(updater.send(:ensure_credit_card)).to be false
          end.to_not change(payment, :source).from(nil)
        end
      end

      context "when a credit card is specified by the standing order" do
        let(:credit_card) { create(:credit_card) }
        before { allow(updater).to receive(:saved_credit_card) { credit_card } }

        it "returns true and stores the credit card as the payment source" do
          expect do
            expect(updater.send(:ensure_credit_card)).to be true
          end.to change(payment, :source_id).from(nil).to(credit_card.id)
        end
      end
    end
  end
end
