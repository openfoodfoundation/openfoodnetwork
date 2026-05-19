# frozen_string_literal: true

RSpec.describe Api::Admin::ForOrderCycle::SuppliedProductSerializer do
  subject(:serialized_product) { described_class.new(product, order_cycle:, inventory_enabled:) }

  let(:coordinator) { create(:distributor_enterprise) }
  let(:order_cycle) { instance_double(OrderCycle, coordinator:) }
  let(:inventory_enabled) { false }
  let!(:product) { create(:simple_product) }
  let!(:non_inventory_variant) { product.variants.first }
  let!(:inventory_variant) { create(:variant, product: product.reload) }
  let!(:inventory_item) {
    create(:inventory_item, enterprise: coordinator, variant: inventory_variant, visible: true)
  }

  describe "variants" do
    context "when order cycle shows only variants in the coordinator's inventory" do
      before do
        allow(order_cycle).to receive(:prefers_product_selection_from_coordinator_inventory_only?) {
                                true
                              }
      end

      it "ignores the setting and renders all variants" do
        expect(serialized_product.variants.length).to eq(2)
      end

      context "when inventory enabled" do
        let(:inventory_enabled) { true }

        it "renders only variants that are in the coordinators inventory" do
          expect(serialized_product.variants.length).to eq(1)
          expect(serialized_product.variants[0][:id]).to eq(inventory_variant.id)
        end
      end
    end

    context "when order cycle shows all available products" do
      before do
        allow(order_cycle).to receive(:prefers_product_selection_from_coordinator_inventory_only?) {
                                false
                              }
      end

      describe "supplied products" do
        it "renders variants regardless of whether they are in the coordinators inventory" do
          expect(serialized_product.variants.length).to eq(2)
          variant_ids = serialized_product.variants.pluck(:id)
          expect(variant_ids).to include non_inventory_variant.id, inventory_variant.id
        end
      end
    end
  end
end
