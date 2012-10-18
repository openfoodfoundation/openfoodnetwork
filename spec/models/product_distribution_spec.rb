require 'spec_helper'

describe ProductDistribution do
  it "is unique for scope [product, distributor]" do
    pd1 = create(:product_distribution)
    pd1.should be_valid

    new_product = create(:product)
    new_distributor = create(:distributor)

    pd2 = build(:product_distribution, :product => pd1.product, :distributor => pd1.distributor)
    pd2.should_not be_valid

    pd2 = build(:product_distribution, :product => pd1.product, :distributor => new_distributor)
    pd2.should be_valid

    pd2 = build(:product_distribution, :product => new_product, :distributor => pd1.distributor)
    pd2.should be_valid

    pd2 = build(:product_distribution, :product => new_product, :distributor => new_distributor)
    pd2.should be_valid
  end
end
