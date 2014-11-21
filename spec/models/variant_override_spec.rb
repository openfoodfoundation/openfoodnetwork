require 'spec_helper'

describe VariantOverride do
  describe "looking up prices" do
    let(:variant) { create(:variant) }
    let(:hub)     { create(:distributor_enterprise) }

    it "returns the numeric price when present" do
      VariantOverride.create!(variant: variant, hub: hub, price: 12.34)
      VariantOverride.price_for(variant, hub).should == 12.34
    end

    it "returns nil otherwise" do
      VariantOverride.price_for(variant, hub).should be_nil
    end
  end
end
