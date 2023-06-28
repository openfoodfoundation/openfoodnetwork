# frozen_string_literal: true

require 'spec_helper'

module Spree
  module Admin
    describe VariantsController, type: :controller do
      before { controller_login_as_admin }

      describe "#index" do
        describe "deleted variants" do
          let(:product) { create(:product, name: 'Product A') }
          let(:deleted_variant) do
            deleted_variant = product.variants.create(unit_value: "2", price: 1)
            deleted_variant.delete
            deleted_variant
          end

          it "lists only non-deleted variants with params[:deleted] == off" do
            spree_get :index, product_id: product.id, deleted: "off"
            expect(assigns(:variants)).to eq(product.variants)
          end

          it "lists only deleted variants with params[:deleted] == on" do
            spree_get :index, product_id: product.id, deleted: "on"
            expect(assigns(:variants)).to eq([deleted_variant])
          end
        end
      end

      describe "#search" do
        let!(:p1) { create(:simple_product, name: 'Product 1') }
        let!(:p2) { create(:simple_product, name: 'Product 2') }
        let!(:v1) { p1.variants.first }
        let!(:v2) { p2.variants.first }
        let!(:vo) { create(:variant_override, variant: v1, hub: d, count_on_hand: 44) }
        let!(:d)  { create(:distributor_enterprise) }
        let!(:oc) { create(:simple_order_cycle, distributors: [d], variants: [v1]) }

        it "filters by distributor" do
          spree_get :search, q: 'Prod', distributor_id: d.id.to_s
          expect(assigns(:variants)).to eq([v1])
        end

        it "applies variant overrides" do
          spree_get :search, q: 'Prod', distributor_id: d.id.to_s
          expect(assigns(:variants)).to eq([v1])
          expect(assigns(:variants).first.on_hand).to eq(44)
        end

        it "filters by order cycle" do
          spree_get :search, q: 'Prod', order_cycle_id: oc.id.to_s
          expect(assigns(:variants)).to eq([v1])
        end

        it "does not filter when no distributor or order cycle is specified" do
          spree_get :search, q: 'Prod'
          expect(assigns(:variants)).to match_array [v1, v2]
        end
      end

      describe '#destroy' do
        let(:variant) { create(:variant) }

        context 'when requesting with html' do
          before do
            allow(Spree::Variant).to receive(:find).with(variant.id.to_s) { variant }
            allow(variant).to receive(:destroy).and_call_original
          end

          it 'deletes the variant' do
            spree_delete :destroy, id: variant.id, product_id: variant.product.id,
                                   format: 'html'
            expect(variant).to have_received(:destroy)
          end

          it 'shows a success flash message' do
            spree_delete :destroy, id: variant.id, product_id: variant.product.id,
                                   format: 'html'
            expect(flash[:success]).to be
          end

          it 'redirects to admin_product_variants_url' do
            spree_delete :destroy, id: variant.id, product_id: variant.product.id,
                                   format: 'html'
            expect(response).to redirect_to spree.admin_product_variants_url(variant.product.id)
          end

          it 'destroys all its exchanges' do
            exchange = create(:exchange)
            variant.exchanges << exchange

            spree_delete :destroy, id: variant.id, product_id: variant.product.id,
                                   format: 'html'
            expect(variant.exchanges.reload).to be_empty
          end
        end
      end
    end
  end
end
