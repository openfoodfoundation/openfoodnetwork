require 'open_food_network/variant_proxy'

module OpenFoodNetwork
  describe VariantProxy do
    let(:hub) { double(:hub) }
    let(:v)   { double(:variant, sku: 'sku123', price: 'global price') }
    let(:vp) { VariantProxy.new(v, hub) }

    describe "delegating calls to proxied variant" do
      it "delegates sku" do
        vp.sku.should == 'sku123'
      end
    end

    describe "looking up the price" do
      it "returns the override price when there is one" do
        VariantOverride.stub(:price_for) { 'override price' }
        vp.price.should == 'override price'
      end

      it "returns the global price otherwise" do
        VariantOverride.stub(:price_for) { nil }
        vp.price.should == 'global price'
      end
    end
  end
end
