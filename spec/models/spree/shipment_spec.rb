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
  end
end
