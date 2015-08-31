require 'spec_helper'

module Admin
  describe VariantOverridesController, type: :controller do
    include AuthenticationWorkflow
    let!(:hub_owner) { create :admin_user, enterprise_limit: 2 }

    before do
      controller.stub spree_current_user: hub_owner
    end

    describe "bulk_update" do
      context "as an enterprise user I update the variant overrides" do
        let!(:hub) { create(:distributor_enterprise, owner: hub_owner) }
        it "updates the overrides correctly" do
          v1 = create(:variant)
          v2 = create(:variant)
          vo1 = create(:variant_override, hub: hub, variant: v1, price: "6.0", count_on_hand: 5, default_stock: 7)
          vo2 = create(:variant_override, hub: hub, variant: v2, price: "6.0", count_on_hand: 5, default_stock: 7)
          vo1.price = "10.0"
          vo2.default_stock = 12
          # Have to use .attributes as otherwise passes just the ID
          spree_put :bulk_update, {variant_overrides: [vo1.attributes, vo2.attributes]}
	        # Retrieve from database
          VariantOverride.find(vo1.id).price.should eq 10
	        VariantOverride.find(vo2.id).default_stock.should eq 12
        end
      end
    end
    describe "bulk_reset" do
      let!(:hub) { create(:distributor_enterprise, owner: hub_owner) }
      before do
        controller.stub spree_current_user: hub.owner
      end
      context "when a reset request is received" do
        it "updates stock to default values" do
        v1 = create(:variant)
        v2 = create(:variant)
        vo1 = create(:variant_override, hub: hub, variant: v1, price: "6.0", count_on_hand: 5, default_stock: 7, enable_reset: true)
        vo2 = create(:variant_override, hub: hub, variant: v2, price: "6.0", count_on_hand: 2, default_stock: 1, enable_reset: false)
        params = {"variant_overrides" => [vo1.attributes, vo2.attributes]}
        spree_put :bulk_reset, params

        vo1.reload
        expect(vo1.count_on_hand).to eq 7
        end
        it "doesn't update where reset is disabled" do
          v1 = create(:variant)
          v2 = create(:variant)
          vo1 = create(:variant_override, hub: hub, variant: v1, price: "6.0", count_on_hand: 5, default_stock: 7, enable_reset: true)
          vo2 = create(:variant_override, hub: hub, variant: v2, price: "6.0", count_on_hand: 2, default_stock: 1, enable_reset: false)
          params = {"variant_overrides" => [vo1.attributes, vo2.attributes]}
          spree_put :bulk_reset, params
          
          vo2.reload
          expect(vo2.count_on_hand).to eq 2
        end
      end
    end
  end
end
