require 'open_food_network/user_balance_calculator'
require 'spec_helper'

module OpenFoodNetwork
  describe UserBalanceCalculator do

    describe "finding the account balance of a user with a hub" do

      let!(:user1) { create(:user) }
      let!(:hub1) { create(:distributor_enterprise) }

      let!(:o1) { create(:order_with_totals_and_distribution, user: user1, distributor: hub1) } #total=10
      let!(:o2) { create(:order_with_totals_and_distribution, user: user1, distributor: hub1) } #total=10
      let!(:p1) { create(:payment, order: o1, amount: 15.00) }
      let!(:p2) { create(:payment, order: o2, amount: 10.00) }

      it "finds the user balance for this enterprise" do
        UserBalanceCalculator.new(user1, hub1).balance.to_i.should == 5
      end

      context "with another hub" do
        let!(:hub2) { create(:distributor_enterprise) }
        let!(:o3) { create(:order_with_totals_and_distribution,
                           user: user1, distributor: hub2) } #total=10
        let!(:p3) { create(:payment, order: o3, amount: 10.00) }

        it "does not find the balance for other enterprises" do
          UserBalanceCalculator.new(user1, hub2).balance.to_i.should == 0
        end
      end

      context "with another user" do
        let!(:user2) { create(:user) }
        let!(:o4) { create(:order_with_totals_and_distribution,
                           user: user2, distributor: hub1) } #total=10
        let!(:p3) { create(:payment, order: o4, amount: 20.00) }

        it "does not find the balance for other users" do
          UserBalanceCalculator.new(user2, hub1).balance.to_i.should == 10
        end
      end
    end 
  end
end
