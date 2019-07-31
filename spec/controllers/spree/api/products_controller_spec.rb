require 'spec_helper'

module Spree
  describe Spree::Api::ProductsController, type: :controller do
    render_views

    let(:supplier) { create(:supplier_enterprise) }
    let(:supplier2) { create(:supplier_enterprise) }
    let!(:product) { create(:product, supplier: supplier) }
    let!(:inactive_product) { create(:product, available_on: Time.zone.now.tomorrow, name: "inactive") }
    let(:product_other_supplier) { create(:product, supplier: supplier2) }
    let(:product_with_image) { create(:product_with_image, supplier: supplier) }
    let(:attributes) { ["id", "name", "supplier", "price", "on_hand", "available_on", "permalink_live"] }
    let(:all_attributes) { ["id", "name", "description", "price", "available_on", "permalink", "meta_description", "meta_keywords", "shipping_category_id", "taxon_ids", "variants", "option_types", "product_properties"] }

    let(:current_api_user) { build(:user) }

    before do
      allow(controller).to receive(:spree_current_user) { current_api_user }
    end

    context "as a normal user" do
      before do
        allow(current_api_user)
          .to receive(:has_spree_role?).with("admin").and_return(false)
      end

      it "gets a single product" do
        product.master.images.create!(attachment: image("thinking-cat.jpg"))
        product.variants.create!(unit_value: "1", unit_description: "thing")
        product.variants.first.images.create!(attachment: image("thinking-cat.jpg"))
        product.set_property("spree", "rocks")
        api_get :show, id: product.to_param
        expect(json_response).to have_attributes(keys: all_attributes)
        expect(json_response['variants'].first).to have_attributes(keys: ["id", "name", "sku", "price", "weight", "height", "width", "depth", "is_master", "cost_price", "permalink", "option_values", "images"])
        expect(json_response['variants'].first['images'].first).to have_attributes(keys: ["id", "position", "attachment_content_type", "attachment_file_name", "type", "attachment_updated_at", "attachment_width", "attachment_height", "alt", "viewable_type", "viewable_id", "attachment_url"])
        expect(json_response["product_properties"].first).to have_attributes(keys: ["id", "product_id", "property_id", "value", "property_name"])
      end

      context "finds a product by permalink first then by id" do
        let!(:other_product) { create(:product, permalink: "these-are-not-the-droids-you-are-looking-for") }

        before do
          product.update_attribute(:permalink, "#{other_product.id}-and-1-ways")
        end

        specify do
          api_get :show, id: product.to_param
          expect(json_response["permalink"]).to match(/and-1-ways/)
          product.destroy

          api_get :show, id: other_product.id
          expect(json_response["permalink"]).to match(/droids/)
        end
      end

      it "cannot see inactive products" do
        api_get :show, id: inactive_product.to_param
        expect(json_response["error"]).to eq("The resource you were looking for could not be found.")
        expect(response.status).to eq(404)
      end

      it "returns a 404 error when it cannot find a product" do
        api_get :show, id: "non-existant"
        expect(json_response["error"]).to eq("The resource you were looking for could not be found.")
        expect(response.status).to eq(404)
      end

      include_examples "modifying product actions are restricted"
    end

    context "as an enterprise user" do
      let(:current_api_user) do
        user = create(:user)
        user.enterprise_roles.create(enterprise: supplier)
        user
      end

      it "soft deletes my products" do
        spree_delete :soft_delete, product_id: product.to_param, format: :json
        expect(response.status).to eq(204)
        expect { product.reload }.not_to raise_error
        expect(product.deleted_at).not_to be_nil
      end

      it "is denied access to soft deleting another enterprises' product" do
        spree_delete :soft_delete, product_id: product_other_supplier.to_param, format: :json
        assert_unauthorized!
        expect { product_other_supplier.reload }.not_to raise_error
        expect(product_other_supplier.deleted_at).to be_nil
      end
    end

    context "as an administrator" do
      before do
        allow(current_api_user)
          .to receive(:has_spree_role?).with("admin").and_return(true)
      end

      it "soft deletes a product" do
        spree_delete :soft_delete, product_id: product.to_param, format: :json
        expect(response.status).to eq(204)
        expect { product.reload }.not_to raise_error
        expect(product.deleted_at).not_to be_nil
      end

      it "can create a new product" do
        api_post :create, product: { name: "The Other Product",
                                     price: 19.99,
                                     shipping_category_id: create(:shipping_category).id,
                                     supplier_id: supplier.id,
                                     primary_taxon_id: FactoryBot.create(:taxon).id,
                                     variant_unit: "items",
                                     variant_unit_name: "things",
                                     unit_description: "things" }
        expect(json_response).to have_attributes(keys: all_attributes)
        expect(response.status).to eq(201)
      end

      it "cannot create a new product with invalid attributes" do
        api_post :create, product: {}
        expect(response.status).to eq(422)
        expect(json_response["error"]).to eq("Invalid resource. Please fix errors and try again.")
        errors = json_response["errors"]
        expect(errors.keys).to match_array(["name", "price", "primary_taxon", "shipping_category_id", "supplier", "variant_unit"])
      end

      it "can update a product" do
        api_put :update, id: product.to_param, product: { name: "New and Improved Product!" }
        expect(response.status).to eq(200)
      end

      it "cannot update a product with an invalid attribute" do
        api_put :update, id: product.to_param, product: { name: "" }
        expect(response.status).to eq(422)
        expect(json_response["error"]).to eq("Invalid resource. Please fix errors and try again.")
        expect(json_response["errors"]["name"]).to eq(["can't be blank"])
      end

      it "can delete a product" do
        expect(product.deleted_at).to be_nil
        api_delete :destroy, id: product.to_param
        expect(response.status).to eq(204)
        expect(product.reload.deleted_at).not_to be_nil
      end
    end

    describe '#clone' do
      context 'as a normal user' do
        before do
          allow(current_api_user)
            .to receive(:has_spree_role?).with("admin").and_return(false)
        end

        it 'denies access' do
          spree_post :clone, product_id: product.id, format: :json
          assert_unauthorized!
        end
      end

      context 'as an enterprise user' do
        let(:current_api_user) do
          user = create(:user)
          user.enterprise_roles.create(enterprise: supplier)
          user
        end

        it 'responds with a successful response' do
          spree_post :clone, product_id: product.id, format: :json
          expect(response.status).to eq(201)
        end

        it 'clones the product' do
          spree_post :clone, product_id: product.id, format: :json
          expect(json_response['name']).to eq("COPY OF #{product.name}")
        end

        it 'clones a product with image' do
          spree_post :clone, product_id: product_with_image.id, format: :json
          expect(response.status).to eq(201)
          expect(json_response['name']).to eq("COPY OF #{product_with_image.name}")
        end
      end

      context 'as an administrator' do
        before do
          allow(current_api_user)
            .to receive(:has_spree_role?).with("admin").and_return(true)
        end

        it 'responds with a successful response' do
          spree_post :clone, product_id: product.id, format: :json
          expect(response.status).to eq(201)
        end

        it 'clones the product' do
          spree_post :clone, product_id: product.id, format: :json
          expect(json_response['name']).to eq("COPY OF #{product.name}")
        end

        it 'clones a product with image' do
          spree_post :clone, product_id: product_with_image.id, format: :json
          expect(response.status).to eq(201)
          expect(json_response['name']).to eq("COPY OF #{product_with_image.name}")
        end
      end
    end
  end
end
