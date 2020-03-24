require 'open_food_network/user_balance_calculator'
require 'spec_helper'

module OpenFoodNetwork
  describe UserBalanceCalculator do
    describe "finding the account balance of a user with a hub" do
      let!(:user1) { create(:user) }
      let!(:hub1) { create(:distributor_enterprise) }

      let!(:order1) {
        create(:order_with_totals_and_distribution,
               user: user1, distributor: hub1,
               completed_at: 1.day.ago)
      }
      let!(:order2) {
        create(:order_with_totals_and_distribution,
               user: user1, distributor: hub1,
               completed_at: 1.day.ago)
      }
      let!(:payment1) { create(:payment, order: order1, amount: 15.00, state: "completed") }
      let!(:payment2) { create(:payment, order: order2, amount: 2.00, state: "completed") }

      let(:initial_balance) { payment1.amount + payment2.amount - order1.total - order2.total }

      it "finds the correct balance for this email and enterprise" do
        expect(UserBalanceCalculator.new(user1.email, hub1).balance).to eq(initial_balance)
      end

      context "with another hub" do
        let!(:hub2) { create(:distributor_enterprise) }
        let!(:order3) {
          create(:order_with_totals_and_distribution,
                 user: user1, distributor: hub2,
                 completed_at: 1.day.ago)
        }
        let!(:payment3) { create(:payment, order: order3, amount: 55.00, state: "completed") }

        it "does not find the balance for other enterprises" do
          expected_balance = payment3.amount - order3.total
          expect(UserBalanceCalculator.new(user1.email, hub2).balance).to eq(expected_balance)
        end
      end

      context "with another user" do
        let!(:user2) { create(:user) }
        let!(:order4) {
          create(:order_with_totals_and_distribution,
                 user: user2, distributor: hub1,
                 completed_at: 1.day.ago)
        }
        let!(:payment4) { create(:payment, order: order4, amount: 11.00, state: "completed") }

        it "does not find the balance for other users" do
          expected_balance = payment4.amount - order4.total
          expect(UserBalanceCalculator.new(user2.email, hub1).balance).to eq(expected_balance)
        end
      end

      context "with canceled orders" do
        let!(:cancelled_order) {
          create(:order_with_totals_and_distribution,
                 user: user1, distributor: hub1,
                 completed_at: 1.day.ago, state: "canceled")
        }
        let!(:cancelled_order_payment) {
          create(:payment, order: cancelled_order, amount: 25.00, state: "completed")
        }

        it "includes complete payments of canceled orders in the balance (but not the amount of the canceled orders)" do
          expected_balance = initial_balance + cancelled_order_payment.amount
          expect(UserBalanceCalculator.new(user1.email, hub1).balance).to eq(expected_balance)
        end
      end

      context "with void payments" do
        let!(:order5) {
          create(:order_with_totals_and_distribution,
                 user: user1, distributor: hub1,
                 completed_at: 1.day.ago)
        }
        let!(:payment5) { create(:payment, order: order5, amount: 200.00, state: "void") }

        it "does not include void payments in the balance" do
          expected_balance = initial_balance - order5.total
          expect(UserBalanceCalculator.new(user1.email, hub1).balance).to eq(expected_balance)
        end
      end

      context "with invalid payments" do
        let!(:order6) {
          create(:order_with_totals_and_distribution,
                 user: user1, distributor: hub1,
                 completed_at: 1.day.ago)
        }
        let!(:payment6) { create(:payment, order: order6, amount: 20.00, state: "invalid") }

        it "does not include invalid payments in the balance" do
          expected_balance = initial_balance - order6.total
          expect(UserBalanceCalculator.new(user1.email, hub1).balance).to eq(expected_balance)
        end
      end

      context "with multiple payments on single order" do
        let!(:order7) {
          create(:order_with_totals_and_distribution,
                 user: user1, distributor: hub1,
                 completed_at: 1.day.ago)
        }
        let!(:payment7) { create(:payment, order: order7, amount: 4.00, state: "completed") }
        let!(:payment8) { create(:payment, order: order7, amount: 5.00, state: "completed") }
        let!(:payment9) { create(:payment, order: order7, amount: 6.00, state: "completed") }

        it "includes orders with multiple payments in the balance" do
          expected_balance = initial_balance + payment7.amount + payment8.amount \
            + payment9.amount - order7.total

          expect(UserBalanceCalculator.new(user1.email, hub1).balance).to eq(expected_balance)
        end
      end
    end
  end
end
