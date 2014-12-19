require 'open_food_network/user_balance_calculator'
require 'spec_helper'

module OpenFoodNetwork
  describe UserBalanceCalculator do

    let!(:usr) { create(:user) }
    let!(:entrprs) { create(:distributor_enterprise) }
    let!(:userbalancecalc) { UserBalanceCalculator.new(usr, entrprs) }

    describe "for a user and enterprise" do 
  
      let!(:o1) { create(:order_with_totals_and_distribution, user: usr, distributor: entrprs) } #total=10
      let!(:o2) { create(:order_with_totals_and_distribution, user: usr, distributor: entrprs) } #total=10
      let!(:p1) { create(:payment, order: o1, amount: 15.00) }
      let!(:p2) { create(:payment, order: o2, amount: 10.00) }

        
      it "finds the user balance for this enterprise" do
        userbalancecalc.balance_for(usr, entrprs).to_i.should == 5
      end

      it "does not find the balance for other enterprises" do
        entrprs2 = create(:distributor_enterprise)
        o3 = create(:order_with_totals_and_distribution, user: usr, distributor: entrprs2) #total=10
        p3 = create(:payment, order: o3, amount: 10.00)
        userbalancecalc.balance_for(usr, entrprs2).to_i.should == 0
      end

      it "does not find the balance for other users" do
        usr2 = create(:user) 
	o4 = create(:order_with_totals_and_distribution, user: usr2, distributor: entrprs) #total=10     
        p3 = create(:payment, order: o4, amount: 20.00)
        userbalancecalc.balance_for(usr2, entrprs).to_i.should == 10
      end

    end

  end
end

