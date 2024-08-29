# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe AffiliateSalesQuery do
  subject(:query) { described_class }

  describe ".label_row" do
    it "converts an array to a hash" do
      row = [
        "Apples",
        "item", "item", nil, nil,
        15.50,
        "3210", "3211",
        3,
      ]
      expect(query.label_row(row)).to eq(
        {
          product_name: "Apples",
          unit_name: "item",
          unit_type: "item",
          units: nil,
          unit_presentation: nil,
          price: 15.50,
          distributor_postcode: "3210",
          supplier_postcode: "3211",
          quantity_sold: 3,
        }
      )
    end
  end
end
