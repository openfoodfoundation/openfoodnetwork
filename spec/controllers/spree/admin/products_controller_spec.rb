require 'spec_helper'

describe Spree::Admin::ProductsController do
  describe "updating a product we do not have access to" do
    let(:s_managed) { create(:enterprise) }
    let(:s_unmanaged) { create(:enterprise) }
    let(:p) { create(:simple_product, supplier: s_unmanaged, name: 'Peas') }

    before do
      login_as_enterprise_user [s_managed]
      spree_post :bulk_update, {"products" => [{"id" => p.id, "name" => "Pine nuts"}]}
    end

    it "denies access" do
      response.should redirect_to "http://test.host/unauthorized"
    end

    it "does not update any product" do
      p.reload.name.should_not == "Pine nuts"
    end
  end

  context "creating a new product" do
    before { login_as_admin }

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
