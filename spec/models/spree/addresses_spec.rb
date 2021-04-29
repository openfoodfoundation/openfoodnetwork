# frozen_string_literal: true

require 'spec_helper'

describe Spree::Address do
  let(:address) { build(:address) }
  let(:enterprise_address) { build(:address, enterprise: build(:enterprise)) }

  describe "associations" do
    it { is_expected.to have_one(:enterprise) }
  end

  describe "destroy" do
    it "can be deleted" do
      expect { address.destroy }.to_not raise_error
    end

    it "cannot be deleted with associated enterprise" do
      expect do
        enterprise_address.destroy
      end.to raise_error ActiveRecord::DeleteRestrictionError
    end
  end

  describe "#full_name_reverse" do
    it "joins last name and first name" do
      address.firstname = "Jane"
      address.lastname = "Doe"
      expect(address.full_name_reverse).to eq("Doe Jane")
    end

    it "is last name when first name is blank" do
      address.firstname = ""
      address.lastname = "Doe"
      expect(address.full_name_reverse).to eq("Doe")
    end

    it "is first name when last name is blank" do
      address.firstname = "Jane"
      address.lastname = ""
      expect(address.full_name_reverse).to eq("Jane")
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
      expect do
        Spree::Address.new.country = "A country"
      end.to raise_error ActiveRecord::AssociationTypeMismatch
    end
  end
end
