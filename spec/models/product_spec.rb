require 'spec_helper'

describe Spree::Product do

  describe "associations" do
    it { should belong_to(:supplier) }
    it { should have_many(:product_distributions) }
  end

  describe "validations" do
    it "is valid when created from factory" do
      create(:product).should be_valid
    end

    it "requires a supplier" do
      product = create(:product)
      product.supplier = nil
      product.should_not be_valid
    end
  end

end
