require 'spec_helper'

describe Spree::Address do
  describe "associations" do
    it { should have_one(:enterprise) }
  end

  describe "delegation" do
    it { should delegate(:name).to(:state).with_prefix }
  end

  describe "geocode address" do
    let(:address) { FactoryGirl.build(:address) }

    it "should include address1, address2, zipcode, city, state and country" do
      address.geocode_address.should include(address.address1)
      address.geocode_address.should include(address.address2)
      address.geocode_address.should include(address.zipcode)
      address.geocode_address.should include(address.city)
      address.geocode_address.should include(address.state.name)
      address.geocode_address.should include(address.country.name)
    end

    it "should not include empty fields" do
      address.address2 = nil
      address.city = ""

      address.geocode_address.split(',').length.should eql(4)
    end
  end

  describe "full address" do
    let(:address) { FactoryGirl.build(:address) }

    it "should include address1, address2, zipcode, city and state" do
      address.full_address.should include(address.address1)
      address.full_address.should include(address.address2)
      address.full_address.should include(address.zipcode)
      address.full_address.should include(address.city)
      address.full_address.should include(address.state.name)
      address.full_address.should_not include(address.country.name)
    end

    it "should not include empty fields" do
      address.address2 = nil
      address.city = ""

      address.full_address.split(',').length.should eql(3)
    end
  end

  describe "setters" do
    it "lets us set a country" do
      expect { Spree::Address.new.country = "A country" }.to raise_error ActiveRecord::AssociationTypeMismatch
    end
  end

  describe "notifying bugsnag when saved with missing data" do
    it "notifies on create" do
      Bugsnag.should_receive(:notify)
      a = Spree::Address.new zipcode: nil
      a.save validate: false
    end

    it "notifies on update" do
      Bugsnag.should_receive(:notify)
      a = create(:address)
      a.zipcode = nil
      a.save validate: false
    end
  end
end
