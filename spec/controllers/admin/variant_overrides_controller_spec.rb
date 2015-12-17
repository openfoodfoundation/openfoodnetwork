require 'spec_helper'

describe Admin::VariantOverridesController, type: :controller do
  # include AuthenticationWorkflow

  describe "bulk_update" do
    context "json" do
      let(:format) { :json }

      let(:hub) { create(:distributor_enterprise) }
      let(:variant) { create(:variant) }
      let!(:variant_override) { create(:variant_override, hub: hub, variant: variant) }
      let(:variant_override_params) { [ { id: variant_override.id, price: 123.45, count_on_hand: 321, sku: "MySKU", on_demand: false } ] }

      context "where I don't manage the variant override hub" do
        before do
          user = create(:user)
          user.owned_enterprises << create(:enterprise)
          controller.stub spree_current_user: user
        end

        it "redirects to unauthorized" do
          spree_put :bulk_update, format: format, variant_overrides: variant_override_params
          expect(response).to redirect_to spree.unauthorized_path
        end
      end

      context "where I manage the variant override hub" do
        before do
          controller.stub spree_current_user: hub.owner
        end

        context "but the producer has not granted VO permission" do
          it "redirects to unauthorized" do
            spree_put :bulk_update, format: format, variant_overrides: variant_override_params
            expect(response).to redirect_to spree.unauthorized_path
          end
        end

        context "and the producer has granted VO permission" do
          before do
            create(:enterprise_relationship, parent: variant.product.supplier, child: hub, permissions_list: [:create_variant_overrides])
          end

          it "allows me to update the variant override" do
            spree_put :bulk_update, format: format, variant_overrides: variant_override_params
            variant_override.reload
            expect(variant_override.price).to eq 123.45
            expect(variant_override.count_on_hand).to eq 321
            expect(variant_override.sku).to eq "MySKU"
            expect(variant_override.on_demand).to eq false
          end
        end
      end
    end
  end
end
