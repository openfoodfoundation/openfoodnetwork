require 'open_food_network/user_balance_calculator'
require 'spec_helper'

module OpenFoodNetwork
  describe UserBalanceCalculator do
    describe "finding the account balance of a user with a hub" do
      let!(:user1) { create(:user) }
      let!(:hub1) { create(:distributor_enterprise) }

      let!(:o1) {
        create(:order_with_totals_and_distribution,
               user: user1, distributor: hub1,
               completed_at: 1.day.ago)
      } # total=13 (10 + 3 shipping fee)
      let!(:o2) {
        create(:order_with_totals_and_distribution,
               user: user1, distributor: hub1,
               completed_at: 1.day.ago)
      } # total=13 (10 + 3 shipping fee)
      let!(:p1) {
        create(:payment, order: o1, amount: 15.00,
                         state: "completed")
      }
      let!(:p2) {
        create(:payment, order: o2, amount: 2.00,
                         state: "completed")
      }

      it "finds the correct balance for this email and enterprise" do
        expect(UserBalanceCalculator.new(o1.email, hub1).balance).to eq(-9) # = 15 + 2 - 13 - 13
      end

      context "with another hub" do
        let!(:hub2) { create(:distributor_enterprise) }
        let!(:o3) {
          create(:order_with_totals_and_distribution,
                 user: user1, distributor: hub2,
                 completed_at: 1.day.ago)
        } # total=13 (10 + 3 shipping fee)
        let!(:p3) {
          create(:payment, order: o3, amount: 15.00,
                           state: "completed")
        }

        it "does not find the balance for other enterprises" do
          expect(UserBalanceCalculator.new(o3.email, hub2).balance).to eq(2) # = 15 - 13
        end
      end

      context "with another user" do
        let!(:user2) { create(:user) }
        let!(:o4) {
          create(:order_with_totals_and_distribution,
                 user: user2, distributor: hub1,
                 completed_at: 1.day.ago)
        } # total=13 (10 + 3 shipping fee)
        let!(:p3) {
          create(:payment, order: o4, amount: 20.00,
                           state: "completed")
        }

        it "does not find the balance for other users" do
          expect(UserBalanceCalculator.new(o4.email, hub1).balance).to eq(7) # = 20 - 13
        end
      end

      context "with canceled orders" do
        let!(:o4) {
          create(:order_with_totals_and_distribution,
                 user: user1, distributor: hub1,
                 completed_at: 1.day.ago, state: "canceled")
        } # total=10
        let!(:p4) {
          create(:payment, order: o4, amount: 20.00,
                           state: "completed")
        }

        it "does not include canceled orders in the balance" do
          expect(UserBalanceCalculator.new(o4.email, hub1).balance).to eq(-9) # = 15 + 2 - 13 - 13
        end
      end
    end
  end
end
