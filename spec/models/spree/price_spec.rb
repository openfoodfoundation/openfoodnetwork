# frozen_string_literal: true

module Spree
  RSpec.describe Price do
    let(:variant) { create(:variant) }
    let(:price) { variant.default_price }

    context "when variant is soft-deleted" do
      before do
        variant.destroy
      end

      it "can access the variant" do
        expect(price.reload.variant).to eq variant
      end
    end

    context "with large values" do
      let(:expensive_variant) { build(:variant, price: 10_000_000) }

      it "saves without error" do
        expect{ expensive_variant.save }.not_to raise_error
        expect(expensive_variant.persisted?).to be true
      end
    end

    context "with string" do
      it "parses the price" do
        variant.price = " 10.25 eur"
        variant.save

        expect(variant.reload.price).to eq 10.25
      end
    end

    describe "#price=" do
      subject { Spree::Price.new }

      context "with a number" do
        it "returns the same number" do
          subject.price = 12.5

          expect(subject.price).to eq(12.5)
        end
      end

      context "with empty string" do
        it "sets the price to nil" do
          subject.price = ""

          expect(subject.price).to be_nil
        end
      end
    end
  end
end
