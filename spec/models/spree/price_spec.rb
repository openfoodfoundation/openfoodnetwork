# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe Price do
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
        expect{ expensive_variant.save }.to_not raise_error
        expect(expensive_variant.persisted?).to be true
      end
    end
  end
end
