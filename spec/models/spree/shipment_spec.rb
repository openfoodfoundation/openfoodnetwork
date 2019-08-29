require "spec_helper"

describe Spree::Shipment do
  describe "manifest" do
    let!(:product) { create(:product) }
    let!(:order) { create(:order, distributor: product.supplier) }
    let!(:deleted_variant) { create(:variant, product: product) }
    let!(:other_variant) { create(:variant, product: product) }
    let!(:line_item_for_deleted) { create(:line_item, order: order, variant: deleted_variant) }
    let!(:line_item_for_other) { create(:line_item, order: order, variant: other_variant) }
    let!(:shipment) { create(:shipment_with, :shipping_method, order: order) }

    context "when the variant is soft-deleted" do
      before { deleted_variant.delete }

      it "can still access the variant" do
        shipment.reload
        variants = shipment.manifest.map(&:variant).uniq
        expect(variants.sort_by(&:id)).to eq([deleted_variant, other_variant].sort_by(&:id))
      end
    end

    context "when the product is soft-deleted" do
      before { deleted_variant.product.delete }

      it "can still access the variant" do
        shipment.reload
        variants = shipment.manifest.map(&:variant)
        expect(variants.sort_by(&:id)).to eq([deleted_variant, other_variant].sort_by(&:id))
      end
    end

    context "when the order contains items with negative stock" do
      let!(:on_demand_variant) { create(:variant, on_demand: true, on_hand: 1) }
      let!(:pending_order) { create(:completed_order_with_totals) }
      let!(:backordered_line_item) {
        create(:line_item, order: pending_order, variant: on_demand_variant, quantity: 99)
      }

      before do
        pending_order.payments << create(:payment, amount: pending_order.total, state: 'completed')
        pending_order.update!
      end

      it "can still be shipped" do
        expect(pending_order.can_ship?).to be true
        expect(pending_order.ready_to_ship?).to be true
      end
    end
  end
end
