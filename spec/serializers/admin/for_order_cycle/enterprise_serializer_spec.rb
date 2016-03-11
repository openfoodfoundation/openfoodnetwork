describe Api::Admin::ForOrderCycle::EnterpriseSerializer do
  let(:coordinator)         { create(:distributor_enterprise) }
  let(:order_cycle)         { double(:order_cycle, coordinator: coordinator) }
  let(:enterprise)          { create(:distributor_enterprise) }
  let!(:non_inventory_product) { create(:simple_product, supplier: enterprise) }
  let!(:non_inventory_variant)  { non_inventory_product.variants.first }
  let!(:inventory_product)  { create(:simple_product, supplier: enterprise) }
  let!(:inventory_variant)  { inventory_product.variants.first }
  let!(:deleted_product)    { create(:simple_product, supplier: enterprise, deleted_at: 24.hours.ago ) }
  let!(:deleted_variant)  { deleted_product.variants.first }
  let(:serialized_enterprise) { Api::Admin::ForOrderCycle::EnterpriseSerializer.new(enterprise, order_cycle: order_cycle, spree_current_user: enterprise.owner ).to_json }
  let!(:inventory_item1) { create(:inventory_item, enterprise: coordinator, variant: inventory_variant, visible: true)}
  let!(:inventory_item2) { create(:inventory_item, enterprise: coordinator, variant: deleted_variant, visible: true)}

  context "when order cycle shows only variants in the coordinator's inventory" do
    before do
      allow(order_cycle).to receive(:prefers_product_selection_from_coordinator_inventory_only?) { true }
    end

    describe "supplied products" do
      it "renders only non-deleted variants that are in the coordinators inventory" do
        expect(serialized_enterprise).to have_json_size(1).at_path 'supplied_products'
        expect(serialized_enterprise).to have_json_size(1).at_path 'supplied_products/0/variants'
        expect(serialized_enterprise).to be_json_eql(inventory_variant.id).at_path 'supplied_products/0/variants/0/id'
      end
    end
  end


  context "when order cycle shows all available products" do
    before do
      allow(order_cycle).to receive(:prefers_product_selection_from_coordinator_inventory_only?) { false }
    end

    describe "supplied products" do
      it "renders variants that are not in the coordinators inventory but not variants of deleted products" do
        expect(serialized_enterprise).to have_json_size(2).at_path 'supplied_products'
        expect(serialized_enterprise).to have_json_size(1).at_path 'supplied_products/0/variants'
        expect(serialized_enterprise).to have_json_size(1).at_path 'supplied_products/1/variants'
        variant_ids = parse_json(serialized_enterprise)['supplied_products'].map{ |p| p['variants'].first['id'] }
        expect(variant_ids).to include non_inventory_variant.id, inventory_variant.id
      end
    end
  end

end
