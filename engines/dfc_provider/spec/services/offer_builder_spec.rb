# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe OfferBuilder do
  let(:variant) { build(:variant, id: 5) }

  describe ".offer" do
    it "assigns a stock level" do
      # Assigning stock only works with persisted records:
      variant.save!
      variant.on_hand = 5

      offer = OfferBuilder.build(variant)

      expect(offer.stockLimitation).to eq 5
    end

    it "has no stock limitation when on demand" do
      # Assigning stock only works with persisted records:
      variant.save!
      variant.on_hand = 5
      variant.on_demand = true

      offer = OfferBuilder.build(variant)

      expect(offer.stockLimitation).to eq nil
    end

    it "assigns a price with mapped currency" do
      offer = OfferBuilder.build(variant)

      expect(offer.price.value).to eq 19.99
      expect(offer.price.unit).to eq "dfc-m:AustralianDollar" # Hopefully change to ISO 4217 soon
    end

    it "assigns a price when unknown currency" do
      variant.default_price.currency = "XXX"
      offer = OfferBuilder.build(variant)

      expect(offer.price.value).to eq 19.99
      expect(offer.price.unit).to be nil
    end
  end
end
