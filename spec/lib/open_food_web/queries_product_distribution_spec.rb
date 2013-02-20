require 'open_food_web/queries_product_distribution'

module OpenFoodWeb
  describe QueriesProductDistribution do
    it "fetches active distributors" do
      d1 = double(:distributor_a, name: 'a')
      d2 = double(:distributor_b, name: 'b')
      d3 = double(:distributor_c, name: 'c')

      QueriesProductDistribution.should_receive(:active_distributors_for_product_distributions).and_return([d1, d3])
      QueriesProductDistribution.should_receive(:active_distributors_for_order_cycles).and_return([d1, d2])
      QueriesProductDistribution.active_distributors.should == [d1, d2, d3]
    end
  end
end
