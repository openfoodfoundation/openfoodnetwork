# frozen_string_literal: true

require 'spec_helper'

module Spree
  module Admin
    describe ShippingCategoriesController, type: :controller do
      include AuthenticationHelper

      describe "#create and #update" do
        before { controller_login_as_admin }

        it "creates a shipping shipping category" do
          expect {
            spree_post :create, shipping_category: { name: "Frozen" }
          }.to change { Spree::ShippingCategory.count }.by(1)

          expect(response).to redirect_to spree.admin_shipping_categories_url
        end

        it "updates an existing shipping category" do
          shipping_category = create(:shipping_category)
          spree_put :update, id: shipping_category.id,
                             shipping_category: { name: "Super Frozen" }

          expect(response).to redirect_to spree.admin_shipping_categories_url
          expect(shipping_category.reload.name).to eq "Super Frozen"
        end

        it "deletes an existing shipping category" do
          shipping_category = create(:shipping_category)
          expect {
            spree_delete :destroy, id: shipping_category.id
          }.to change { Spree::ShippingCategory.count }.by(-1)

          expect(response).to redirect_to spree.admin_shipping_categories_url
        end
      end
    end
  end
end
