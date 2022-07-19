# frozen_string_literal: true

require "spec_helper"

describe AddressTransformation do
  include AddressTransformation

  describe "#transform_address!" do
    describe "default cases" do
      let(:attributes) do
        { shipping_address: CustomerSchema.address_example,
          billing_address: CustomerSchema.address_example }
      end

      let(:wanted_address) do
        CustomerSchema.address_example.
          except( :first_name, :last_name, :locality,
                  :postal_code, :region, :street_address_1, :street_address_2).
          merge(
            firstname: "Alice",
            lastname: "Springs",
            address1: "1 Flinders Street",
            address2: "",
            zipcode: "1234",
            city: "Melbourne",
            state: Spree::State.find_by(name: "Victoria"),
            country: Spree::Country.find_by(name: "Australia"),
          )
      end

      it "transforms the shipping_address and the billing_address" do
        transformed_address = transform_address!(attributes, :shipping_address, :ship_address)
        expect(transformed_address).to eq(wanted_address)
        expect(attributes["ship_address_attributes"]).to eq(wanted_address)

        transformed_address = transform_address!(attributes, :billing_address, :bill_address)
        expect(transformed_address).to eq( wanted_address)
        expect(attributes["bill_address_attributes"]).to eq(wanted_address)
      end
    end

    describe "when the address attributes are nil" do
      let(:attributes) do
        { shipping_address: nil,
          billing_address: nil }
      end

      it "returns nil" do
        transformed_address = transform_address!(attributes, :shipping_address, :ship_address)
        expect(transformed_address).to be_nil
        expect(attributes["ship_address_attributes"]).to be_nil

        transformed_address = transform_address!(attributes, :billing_address, :bill_address)
        expect(transformed_address).to be_nil
        expect(attributes["bill_address_attributes"]).to be_nil
      end
    end

    describe "when attributes doesn't contains the searched key" do
      let(:attributes) do
        {
          address: CustomerSchema.address_example,
        }
      end

      it "returns nil" do
        transformed_address = transform_address!(attributes, :shipping_address, :ship_address)
        expect(transformed_address).to be_nil
        expect(attributes["ship_address_attributes"]).to be_nil
      end
    end
  end

  describe "#find_state" do
    it "finds the state" do
      state = find_state(
        state: {
          code: "VIC",
          name: "Victoria",
        },
      )
      expect(state).to eq(Spree::State.find_by(name: "Victoria"))
    end
  end

  describe "#find_country" do
    it "finds the country" do
      country = find_country(
        country: {
          code: "AU",
          name: "Australia",
        },
      )
      expect(country).to eq(Spree::Country.find_by(name: "Australia"))
    end
  end
end
