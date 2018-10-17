require 'spec_helper'

describe Spree::Address do
  describe "associations" do
    it { is_expected.to have_one(:enterprise) }
  end

  describe "delegation" do
    it { is_expected.to delegate(:name).to(:state).with_prefix }
  end

  describe "geocode address" do
    let(:address) { FactoryBot.build(:address) }

    it "should include address1, address2, zipcode, city, state and country" do
      expect(address.geocode_address).to include(address.address1)
      expect(address.geocode_address).to include(address.address2)
      expect(address.geocode_address).to include(address.zipcode)
      expect(address.geocode_address).to include(address.city)
      expect(address.geocode_address).to include(address.state.name)
      expect(address.geocode_address).to include(address.country.name)
    end

    it "should not include empty fields" do
      address.address2 = nil
      address.city = ""

      expect(address.geocode_address.split(',').length).to eql(4)
    end
  end

  describe "full address" do
    let(:address) { FactoryBot.build(:address) }

    it "should include address1, address2, zipcode, city and state" do
      expect(address.full_address).to include(address.address1)
      expect(address.full_address).to include(address.address2)
      expect(address.full_address).to include(address.zipcode)
      expect(address.full_address).to include(address.city)
      expect(address.full_address).to include(address.state.name)
      expect(address.full_address).not_to include(address.country.name)
    end

    it "should not include empty fields" do
      address.address2 = nil
      address.city = ""

      expect(address.full_address.split(',').length).to eql(3)
    end
  end

  describe "setters" do
    it "lets us set a country" do
      expect { Spree::Address.new.country = "A country" }.to raise_error ActiveRecord::AssociationTypeMismatch
    end
  end
end
