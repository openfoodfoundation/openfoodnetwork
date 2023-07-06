# frozen_string_literal: true

require 'spec_helper'
require 'spree/core/product_duplicator'

describe Api::V0::ProductsController, type: :controller do
  render_views

  let(:supplier) { create(:supplier_enterprise) }
  let(:supplier2) { create(:supplier_enterprise) }
  let!(:product) { create(:product, supplier: supplier) }
  let!(:other_product) { create(:product) }
  let(:product_other_supplier) { create(:product, supplier: supplier2) }
  let(:product_with_image) { create(:product_with_image, supplier: supplier) }
  let(:all_attributes) { ["id", "name", "variants"] }
  let(:variants_attributes) {
    ["id", "options_text", "unit_value", "unit_description", "unit_to_display", "on_demand",
     "display_as", "display_name", "name_to_display", "sku", "on_hand", "price"]
  }

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
      product.create_image!(attachment: image("thinking-cat.jpg"))
      product.variants.create!(unit_value: "1", unit_description: "thing", price: 1)
      product.variants.first.images.create!(attachment: image("thinking-cat.jpg"))
      product.set_property("spree", "rocks")
      api_get :show, id: product.to_param

      expect(all_attributes.all?{ |attr| json_response.keys.include? attr }).to eq(true)
      expect(variants_attributes.all?{ |attr|
               json_response['variants'].first.keys.include? attr
             } ).to eq(true)
    end

    it "returns a 404 error when it cannot find a product" do
      api_get :show, id: "non-existant"

      expect(json_response["error"]).to eq("The resource you were looking for could not be found.")
      expect(response.status).to eq(404)
    end

    include_examples "modifying product actions are restricted"
  end

  context "as an enterprise user" do
    let(:current_api_user) { supplier_enterprise_user(supplier) }

    it "can delete my product" do
      expect(product.deleted_at).to be_nil
      api_delete :destroy, id: product.to_param

      expect(response.status).to eq(204)
      expect { product.reload }.not_to raise_error
      expect(product.deleted_at).not_to be_nil
    end

    it "is denied access to deleting another enterprises' product" do
      expect(product_other_supplier.deleted_at).to be_nil
      api_delete :destroy, id: product_other_supplier.to_param

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

    it "can create a new product" do
      api_post :create, product: { name: "The Other Product",
                                   price: 123.45,
                                   shipping_category_id: create(:shipping_category).id,
                                   supplier_id: supplier.id,
                                   primary_taxon_id: FactoryBot.create(:taxon).id,
                                   variant_unit: "items",
                                   variant_unit_name: "things",
                                   unit_description: "things" }

      expect(all_attributes.all?{ |attr| json_response.keys.include? attr }).to eq(true)
      expect(response.status).to eq(201)
      expect(Spree::Product.last.variants.first.price).to eq 123.45
    end

    it "cannot create a new product with invalid attributes" do
      api_post :create, product: {}

      expect(response.status).to eq(422)
      expect(json_response["error"]).to eq("Invalid resource. Please fix errors and try again.")
      errors = json_response["errors"]
      expect(errors.keys).to match_array(["name", "primary_taxon", "shipping_category",
                                          "supplier", "variant_unit"])
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
      let(:current_api_user) { supplier_enterprise_user(supplier) }
      let!(:variant) { create(:variant, product_id: product.id) }

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

      # test cases related to bug #660: product duplication clones master variant

      # stock info - clone is set to zero
      it '(does not) clone the stock info of the product' do
        spree_post :clone, product_id: product.id, format: :json
        expect(json_response['on_hand']).to eq(0)
      end

      # variants: only the master variant of the product is cloned
      it '(does not) clone variants from a product with several variants' do
        spree_post :clone, product_id: product.id, format: :json
        expect(Spree::Product.second.variants.count).not_to eq Spree::Product.first.variants.count
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

  describe '#bulk_products' do
    context "as an enterprise user" do
      let!(:taxon) { create(:taxon) }
      let!(:product2) { create(:product, supplier: supplier, primary_taxon: taxon) }
      let!(:product3) { create(:product, supplier: supplier2, primary_taxon: taxon) }
      let!(:product4) { create(:product, supplier: supplier2) }
      let(:current_api_user) { supplier_enterprise_user(supplier) }

      before { current_api_user.enterprise_roles.create(enterprise: supplier2) }

      it "returns a list of products" do
        api_get :bulk_products, { page: 1, per_page: 15 }, format: :json
        expect(returned_product_ids).to eq [product4.id, product3.id, product2.id,
                                            other_product.id, product.id]
      end

      it "returns pagination data" do
        api_get :bulk_products, { page: 1, per_page: 15 }, format: :json
        expect(json_response['pagination']).to eq "results" => 5, "pages" => 1, "page" => 1,
                                                  "per_page" => 15
      end

      it "uses defaults when page and per_page are not supplied" do
        api_get :bulk_products, format: :json
        expect(json_response['pagination']).to eq "results" => 5, "pages" => 1, "page" => 1,
                                                  "per_page" => 15
      end

      it "returns paginated products by page" do
        api_get :bulk_products, { page: 1, per_page: 2 }, format: :json
        expect(returned_product_ids).to eq [product4.id, product3.id]

        api_get :bulk_products, { page: 2, per_page: 2 }, format: :json
        expect(returned_product_ids).to eq [product2.id, other_product.id]
      end

      it "filters results by supplier" do
        api_get :bulk_products, { page: 1, per_page: 15, q: { supplier_id_eq: supplier.id } },
                format: :json
        expect(returned_product_ids).to eq [product2.id, other_product.id, product.id]
      end

      it "filters results by product category" do
        api_get :bulk_products, { page: 1, per_page: 15, q: { primary_taxon_id_eq: taxon.id } },
                format: :json
        expect(returned_product_ids).to eq [product3.id, product2.id]
      end

      it "filters results by import_date" do
        product.variants.first.update_attribute :import_date, 1.day.ago
        product2.variants.first.update_attribute :import_date, 2.days.ago
        product3.variants.first.update_attribute :import_date, 1.day.ago

        api_get :bulk_products, { page: 1, per_page: 15, import_date: 1.day.ago.to_date.to_s },
                format: :json
        expect(returned_product_ids).to eq [product3.id, product.id]
      end
    end
  end

  private

  def supplier_enterprise_user(enterprise)
    user = create(:user)
    user.enterprise_roles.create(enterprise: enterprise)
    user
  end

  def returned_product_ids
    json_response['products'].map{ |obj| obj['id'] }
  end
end
