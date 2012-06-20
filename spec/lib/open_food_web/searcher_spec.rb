require 'spec_helper'
require 'open_food_web/searcher'

module OpenFoodWeb
  describe Searcher do
    it "searches by supplier" do
      # Given products under two suppliers
      s1 = create(:supplier)
      s2 = create(:supplier)
      p1 = create(:product, :supplier => s1)
      p2 = create(:product, :supplier => s2)

      # When we search for one supplier, we should see only products from that supplier
      searcher = Searcher.new(:supplier_id => s1.id.to_s)
      products = searcher.retrieve_products
      products.should == [p1]
    end

    it "searches by distributor" do
      # Given products under two distributors
      d1 = create(:distributor)
      d2 = create(:distributor)
      p1 = create(:product, :distributors => [d1])
      p2 = create(:product, :distributors => [d2])

      # When we search for one distributor, we should see only products from that distributor
      searcher = Searcher.new(:distributor_id => d1.id.to_s)
      products = searcher.retrieve_products
      products.should == [p1]
    end
  end
end
