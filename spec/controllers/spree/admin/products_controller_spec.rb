require 'spec_helper'

describe Spree::Admin::ProductsController do
  context "Creating a new product" do
    before do
      login_as_admin
    end

    it "redirects to bulk_edit when the user hits 'create'" do
      s = create(:supplier_enterprise)
      t = create(:taxon)
      spree_post :create, {
        product: {
          name: "Product1",
          supplier_id: s.id,
          price: 5.0,
          on_hand: 5,
          variant_unit: 'weight',
          variant_unit_scale: 1000,
          unit_value: 10,
          unit_description: "",
          primary_taxon_id: t.id
        },
        button: 'create'
      }
      response.should redirect_to "/admin/products/bulk_edit"
    end

    it "redirects to new when the user hits 'add_another'" do
      s = create(:supplier_enterprise)
      t = create(:taxon)
      spree_post :create, {
        product: {
          name: "Product1",
          supplier_id: s.id,
          price: 5.0,
          on_hand: 5,
          variant_unit: 'weight',
          variant_unit_scale: 1000,
          unit_value: 10,
          unit_description: "",
          primary_taxon_id: t.id
        },
        button: 'add_another'
      }
      response.should redirect_to "/admin/products/new"
    end
  end
end
