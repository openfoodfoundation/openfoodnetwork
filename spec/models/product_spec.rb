require 'spec_helper'

describe Spree::Product do

  describe "associations" do
    it { should belong_to(:supplier) }
    it { should have_and_belong_to_many(:distributors) }
  end

  describe "validations" do
    it "is valid when created from factory" do
      build(:product).should be_valid
    end

    it "requires at least one distributor" do
      product = build(:product)
      product.distributors.clear
      product.should_not be_valid
    end
  end

end
