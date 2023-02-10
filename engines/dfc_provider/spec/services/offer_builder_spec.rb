# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe DfcBuilder do
  let(:variant) { build(:variant) }

  describe ".offer" do
    it "assigns a stock level" do
      # Assigning stock only works with persisted records:
      variant.save!
      variant.on_hand = 5

      offer = DfcBuilder.offer(variant)

      expect(offer.stockLimitation).to eq 5
    end

    it "has no stock limitation when on demand" do
      # Assigning stock only works with persisted records:
      variant.save!
      variant.on_hand = 5
      variant.on_demand = true

      offer = DfcBuilder.offer(variant)

      expect(offer.stockLimitation).to eq nil
    end
  end
end
