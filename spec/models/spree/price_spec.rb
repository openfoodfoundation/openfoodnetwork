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
  end
end
