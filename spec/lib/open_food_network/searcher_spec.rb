require 'spec_helper'
require 'open_food_network/searcher'

module OpenFoodNetwork
  describe Searcher do
    it "searches by supplier" do
      # Given products under two suppliers
      s1 = create(:supplier_enterprise)
      s2 = create(:supplier_enterprise)
      p1 = create(:product, :supplier => s1)
      p2 = create(:product, :supplier => s2)

      # When we search for one supplier, we should see only products from that supplier
      searcher = Searcher.new(:supplier_id => s1.id.to_s)
      products = searcher.retrieve_products
      products.should == [p1]
    end

    it "searches by distributor" do
      # Given products under two distributors
      d1 = create(:distributor_enterprise)
      d2 = create(:distributor_enterprise)
      p1 = create(:product, :distributors => [d1])
      p2 = create(:product, :distributors => [d2])

      # When we search for one distributor, we should see only products from that distributor
      searcher = Searcher.new(:distributor_id => d1.id.to_s)
      products = searcher.retrieve_products
      products.should == [p1]
    end

    it "searches by supplier or distributor" do
      # Given products under some suppliers and distributors
      s0 = create(:supplier_enterprise)
      s1 = create(:supplier_enterprise)
      d1 = create(:distributor_enterprise)
      p1 = create(:product, :supplier => s1)
      p2 = create(:product, :distributors => [d1])
      p3 = create(:product, :supplier => s0)

      # When we search by the supplier enterprise, we should see the supplied products
      searcher = Searcher.new(:enterprise_id => s1.id.to_s)
      products = searcher.retrieve_products
      products.should == [p1]

      # When we search by the distributor enterprise, we should see the distributed products
      searcher = Searcher.new(:enterprise_id => d1.id.to_s)
      products = searcher.retrieve_products
      products.should == [p2]
    end
  end
end
