# frozen_string_literal: true

require "spec_helper"

RSpec.describe ProductStock do
  let(:product) { create(:simple_product) }

  context "when product has one variant" do
    describe "product.on_hand" do
      it "is the products first variant on_hand" do
        expect(product.on_hand).to eq(product.variants.first.on_hand)
      end
    end
  end

  context 'when product has more than one variant' do
    before do
      product.variants << create(:variant, product:)
    end

    describe "product.on_hand" do
      it "is the sum of the products variants on_hand values" do
        expect(product.on_hand)
          .to eq(product.variants.first.on_hand + product.variants.second.on_hand)
      end
    end
  end
end
