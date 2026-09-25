# frozen_string_literal: true

RSpec.describe Spree::Stock::Quantifier do
  let(:quantifier) { Spree::Stock::Quantifier.new(variant) }
  let(:variant) { create(:variant, on_hand: 99) }

  describe "#total_on_hand" do
    it "sums stock items" do
      expect(quantifier.total_on_hand).to eq 99
    end

    context "with a soft-deleted variant" do
      before do
        variant.delete
      end

      it "returns zero stock for the variant" do
        expect(quantifier.total_on_hand).to eq 0
      end
    end
  end

  describe "loaded_on_hand" do
    it "sums stock items" do
      # Preload data
      variant.stock_items.reload

      expect {
        expect(quantifier.loaded_on_hand).to eq 99
      }.not_to query_database
    end

    context "with a soft-deleted variant" do
      it "returns zero stock for the variant" do
        # Preload data
        variant.stock_items.reload
        variant.delete

        expect {
          expect(quantifier.loaded_on_hand).to eq 0
        }.not_to query_database
      end
    end
  end
end
