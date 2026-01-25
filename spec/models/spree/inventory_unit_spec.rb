# frozen_string_literal: true

RSpec.describe Spree::InventoryUnit do
  let(:variant) { create(:variant) }
  let(:stock_item) { variant.stock_item }

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
    let(:inventory_units) {
      [
        create(:inventory_unit, variant:),
        create(:inventory_unit, variant:)
      ]
    }

    it "finalizes pending units" do
      Spree::InventoryUnit.finalize_units!(inventory_units)
      expect(inventory_units.any?(&:pending)).to be_falsy
    end
  end
end
