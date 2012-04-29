require 'spec_helper'

describe Spree::Supplier do

  describe "associations" do
    it { should have_many(:products) }
  end

  it "should have an address"

  it "should default country to system country" do
    supplier = Spree::Supplier.new

    supplier.country.should == Spree::Country.find_by_id(Spree::Config[:default_country_id])
  end

  describe 'validations' do
    # it{ should validate_presence_of(:comment) }
  end

end
