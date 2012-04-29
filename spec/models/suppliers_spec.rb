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
    it{ should validate_presence_of(:name) }
    it{ should validate_presence_of(:address) }
    it{ should validate_presence_of(:country_id) }
    it{ should validate_presence_of(:state_id) }
    it{ should validate_presence_of(:city) }
    it{ should validate_presence_of(:postcode) }
  end

end
