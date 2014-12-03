require 'open_food_network/product_proxy'
require 'open_food_network/variant_proxy'

module OpenFoodNetwork
  describe ProductProxy do
    let(:hub) { double(:hub) }
    let(:p)   { double(:product, name: 'name') }
    let(:pp) { ProductProxy.new(p, hub) }

    describe "delegating calls to proxied product" do
      it "delegates name" do
        pp.name.should == 'name'
      end
    end

    describe "fetching the variants" do
      let(:v1) { double(:variant) }
      let(:v2) { double(:variant) }
      let(:p) { double(:product, variants: [v1, v2]) }

      it "returns variants wrapped in VariantProxy" do
        # #class is proxied too, so we test that it worked by #object_id
        pp.variants.map(&:object_id).sort.should_not == [v1.object_id, v2.object_id].sort
      end
    end
  end
end
