require 'spec_helper'

module Admin
  describe VariantOverridesController, type: :controller do
    include AuthenticationWorkflow
    let!(:hub_owner) { create :user, enterprise_limit: 2 }
    let!(:v1) { create(:variant) }
    let!(:v2) { create(:variant) }
    let!(:vo1) { create(:variant_override, hub: hub, variant: v1, price: "6.0", count_on_hand: 5, default_stock: 7, enable_reset: true) }
    let!(:vo2) { create(:variant_override, hub: hub, variant: v2, price: "6.0", count_on_hand: 2, default_stock: 1, enable_reset: false) }

    before do
      controller.stub spree_current_user: hub_owner
    end

    describe "bulk_update" do
      let!(:hub) { create(:distributor_enterprise, owner: hub_owner) }
      let(:params) { { variant_overrides: [{id: vo1.id, price: "10.0"}, {id: vo2.id, default_stock: 12 }] } }

      context "where the producer has not granted create_variant_overrides permission to the hub" do
        it "restricts access" do
          spree_put :bulk_update, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "where the producer has granted create_variant_overrides permission to the hub" do
        let!(:er1) { create(:enterprise_relationship, parent: v1.product.supplier, child: hub, permissions_list: [:create_variant_overrides]) }

        it "updates the overrides correctly" do
          spree_put :bulk_update, params
          vo1.reload.price.should eq 10
	        vo2.reload.default_stock.should eq 12
        end
      end
    end

    describe "bulk_reset" do
      let!(:hub) { create(:distributor_enterprise, owner: hub_owner) }

      before do
        controller.stub spree_current_user: hub.owner
      end

      context "where the producer has not granted create_variant_overrides permission to the hub" do
        let(:params) { { variant_overrides: [ { id: vo1 } ] } }

        it "restricts access" do
          spree_put :bulk_reset, params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "where the producer has granted create_variant_overrides permission to the hub" do
        let!(:er1) { create(:enterprise_relationship, parent: v1.product.supplier, child: hub, permissions_list: [:create_variant_overrides]) }

        context "where reset is enabled" do
          let(:params) { { variant_overrides: [ { id: vo1 } ] } }

          it "updates stock to default values" do
            spree_put :bulk_reset, params
            expect(vo1.reload.count_on_hand).to eq 7
          end
        end

        context "where reset is disabled" do
          let(:params) { { variant_overrides: [ { id: vo2 } ] } }
          it "doesn't update on_hand" do
            spree_put :bulk_reset, params
            expect(vo2.reload.count_on_hand).to eq 2
          end
        end
      end
    end
  end
end
