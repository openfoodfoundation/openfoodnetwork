# frozen_string_literal: true

require 'spec_helper'

module Spree
  module Stock
    describe Quantifier do
      let(:quantifier) { Spree::Stock::Quantifier.new(variant) }
      let(:variant) { create(:variant, on_hand: 99) }

      describe "#total_on_hand" do
        context "with a soft-deleted variant" do
          before do
            variant.delete
          end

          it "returns zero stock for the variant" do
            expect(quantifier.total_on_hand).to eq 0
          end
        end
      end
    end
  end
end
