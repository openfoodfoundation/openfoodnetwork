# frozen_string_literal: true

require 'spec_helper'

describe Admin::VariantOverridesController, type: :controller do
  describe "bulk_update" do
    context "json" do
      let(:format) { :json }

      let(:hub) { create(:distributor_enterprise) }
      let(:variant) { create(:variant) }
      let!(:inventory_item) {
        create(:inventory_item, enterprise: hub, variant: variant, visible: true)
      }
      let!(:variant_override) { create(:variant_override, hub: hub, variant: variant) }
      let(:variant_override_params) {
        [{ id: variant_override.id, price: 123.45, count_on_hand: 321, sku: "MySKU",
           on_demand: false }]
      }

      context "where I don't manage the variant override hub" do
        before do
          user = create(:user)
          user.owned_enterprises << create(:enterprise)
          allow(controller).to receive(:spree_current_user) { user }
        end

        it "redirects to unauthorized" do
          put :bulk_update, as: format, params: { variant_overrides: variant_override_params }
          expect(response).to redirect_to unauthorized_path
        end
      end

      context "where I manage the variant override hub" do
        before do
          allow(controller).to receive(:spree_current_user) { hub.owner }
        end

        context "but the producer has not granted VO permission" do
          it "redirects to unauthorized" do
            put :bulk_update, as: format, params: { variant_overrides: variant_override_params }
            expect(response).to redirect_to unauthorized_path
          end

          it 'only authorizes the updated variant overrides' do
            other_variant_override = create(:variant_override, hub: hub, variant: create(:variant))
            expect(controller).not_to receive(:authorize!).with(:update, other_variant_override)

            put :bulk_update, as: format, params: { variant_overrides: variant_override_params }
          end
        end

        context "and the producer has granted VO permission" do
          before do
            create(:enterprise_relationship, parent: variant.product.supplier, child: hub,
                                             permissions_list: [:create_variant_overrides])
          end

          it "loads data" do
            put :bulk_update, as: format, params: { variant_overrides: variant_override_params }
            expect(assigns[:hubs]).to eq [hub]
            expect(assigns[:producers]).to eq [variant.product.supplier]
            expect(assigns[:hub_permissions]).to eq Hash[hub.id, [variant.product.supplier.id]]
            expect(assigns[:inventory_items]).to eq [inventory_item]
          end

          it "allows me to update the variant override" do
            put :bulk_update, as: format, params: { variant_overrides: variant_override_params }

            variant_override.reload
            expect(variant_override.price).to eq 123.45
            expect(variant_override.count_on_hand).to eq 321
            expect(variant_override.sku).to eq "MySKU"
            expect(variant_override.on_demand).to eq false
          end

          context "where params for a variant override are blank" do
            let(:variant_override_params) {
              [{ id: variant_override.id, price: "", count_on_hand: "", default_stock: nil,
                 resettable: nil, sku: nil, on_demand: nil }]
            }

            it "destroys the variant override" do
              put :bulk_update, as: format, params: { variant_overrides: variant_override_params }
              expect(VariantOverride.find_by(id: variant_override.id)).to be_nil
            end
          end

          context "and there is a variant override for a deleted variant" do
            let(:deleted_variant) { create(:variant) }
            let!(:variant_override_of_deleted_variant) {
              create(:variant_override, hub: hub, variant: deleted_variant)
            }

            before { deleted_variant.update_attribute :deleted_at, Time.zone.now }

            it "allows to update other variant overrides" do
              put :bulk_update, as: format, params: { variant_overrides: variant_override_params }

              expect(response).to_not redirect_to unauthorized_path
              variant_override.reload
              expect(variant_override.price).to eq 123.45
            end
          end
        end
      end
    end
  end

  describe "bulk_reset" do
    context "json" do
      let(:format) { :json }

      let(:hub) { create(:distributor_enterprise) }
      let(:producer) { create(:supplier_enterprise) }
      let(:product) { create(:product, supplier: producer) }
      let(:variant1) { create(:variant, product: product) }
      let(:variant2) { create(:variant, product: product) }
      let!(:variant_override1) {
        create(:variant_override, hub: hub, variant: variant1, count_on_hand: 5, default_stock: 7,
                                  resettable: true)
      }
      let!(:variant_override2) {
        create(:variant_override, hub: hub, variant: variant2, count_on_hand: 2, default_stock: 1,
                                  resettable: false)
      }

      let(:params) { { format: format, hub_id: hub.id } }

      context "where I don't manage the variant override hub" do
        before do
          user = create(:user)
          user.owned_enterprises << create(:enterprise)
          allow(controller).to receive(:spree_current_user) { user }
        end

        it "redirects to unauthorized" do
          put :bulk_reset, params: params
          expect(response).to redirect_to unauthorized_path
        end
      end

      context "where I manage the variant override hub" do
        before do
          allow(controller).to receive(:spree_current_user) { hub.owner }
        end

        context "where the producer has not granted create_variant_overrides permission " \
                "to the hub" do
          it "restricts access" do
            put :bulk_reset, params: params
            expect(response).to redirect_to unauthorized_path
          end
        end

        context "where the producer has granted create_variant_overrides permission to the hub" do
          let!(:er1) {
            create(:enterprise_relationship, parent: producer, child: hub,
                                             permissions_list: [:create_variant_overrides])
          }

          it "loads data" do
            put :bulk_reset, params: params
            expect(assigns[:hubs]).to eq [hub]
            expect(assigns[:producers]).to eq [producer]
            expect(assigns[:hub_permissions]).to eq Hash[hub.id, [producer.id]]
            expect(assigns[:inventory_items]).to eq []
          end

          it "updates stock to default values where reset is enabled" do
            expect(variant_override1.reload.count_on_hand).to eq 5 # reset enabled
            expect(variant_override2.reload.count_on_hand).to eq 2 # reset disabled
            put :bulk_reset, params: params
            expect(variant_override1.reload.count_on_hand).to eq 7 # reset enabled
            expect(variant_override2.reload.count_on_hand).to eq 2 # reset disabled
          end

          context "and the producer has granted create_variant_overrides permission " \
                  "to another hub I manage" do
            before { hub.owner.update_attribute(:enterprise_limit, 2) }
            let(:hub2) { create(:distributor_enterprise, owner: hub.owner) }
            let(:product) { create(:product, supplier: producer) }
            let(:variant3) { create(:variant, product: product) }
            let!(:variant_override3) {
              create(:variant_override, hub: hub2, variant: variant3, count_on_hand: 1,
                                        default_stock: 13, resettable: true)
            }
            let!(:er2) {
              create(:enterprise_relationship, parent: producer, child: hub2,
                                               permissions_list: [:create_variant_overrides])
            }

            it "does not reset count_on_hand for variant_overrides not in params" do
              expect {
                put :bulk_reset, params: params
              }.to_not change{ variant_override3.reload.count_on_hand }
            end
          end
        end
      end
    end
  end
end
