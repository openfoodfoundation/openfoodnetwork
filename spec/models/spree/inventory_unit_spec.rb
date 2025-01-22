# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::InventoryUnit do
  let!(:stock_location) { create(:stock_location_with_items) }
  let(:stock_item) { Spree::StockItem.order(:id).first }

  context "variants deleted" do
    let!(:unit) do
      Spree::InventoryUnit.create(variant: stock_item.variant)
    end

    it "can still fetch variant" do
      unit.variant.destroy
      expect(unit.reload.variant).to be_a Spree::Variant
    end
  end

  context "#finalize_units!" do
    let!(:stock_location) { create(:stock_location) }
    let(:variant) { create(:variant) }
    let(:inventory_units) {
      [
        create(:inventory_unit, variant:),
        create(:inventory_unit, variant:)
      ]
    }

    it "should create a stock movement" do
      Spree::InventoryUnit.finalize_units!(inventory_units)
      expect(inventory_units.any?(&:pending)).to be_falsy
    end
  end
end
