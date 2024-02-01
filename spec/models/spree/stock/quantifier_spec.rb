# frozen_string_literal: true

require 'spec_helper'

module Spree
  module Stock
    describe Quantifier do
      include DatabaseHelper

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

        it "doesn't create extra query on subsequent calls" do
          quantifier
          expect do
            quantifier.total_on_hand
            quantifier.total_on_hand
          end.to query_database [
            "Spree::StockItem Sum"
          ]
        end
      end

      describe "#backorderable" do
        describe "eager-loading stock_items" do
          it "doesn't create extra query for stock_items" do
            variant_loaded = Variant.where(id: variant).includes(:stock_items).first
            expect do
              Spree::Stock::Quantifier.new(variant_loaded).backorderable?
            end.to query_database []
          end
        end
      end
    end
  end
end
