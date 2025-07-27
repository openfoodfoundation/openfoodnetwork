# frozen_string_literal: true

require 'spec_helper'
require 'spree/core/product_duplicator'

RSpec.describe Api::V0::ProductsController do
  render_views

  let(:supplier) { create(:supplier_enterprise) }
  let(:supplier2) { create(:supplier_enterprise) }
  let!(:product) { create(:product, supplier_id: supplier.id) }
  let!(:other_product) { create(:product, supplier_id: supplier.id) }
  let(:product_other_supplier) { create(:product, supplier_id: supplier2.id) }
  let(:product_with_image) { create(:product_with_image, supplier_id: supplier.id) }
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
    let(:taxon) { create(:taxon) }
    let(:attachment) { fixture_file_upload("thinking-cat.jpg") }

    before do
      allow(current_api_user)
        .to receive(:admin?).and_return(false)
    end

    it "gets a single product" do
      product.create_image!(attachment:)
      product.variants.create!(unit_value: "1", variant_unit: "weight", variant_unit_scale: 1,
                               unit_description: "thing", price: 1, primary_taxon: taxon, supplier:)
      product.variants.first.images.create!(attachment:)
      product.set_property("spree", "rocks")

      api_get :show, id: product.to_param

      expect(json_response.keys).to include(*all_attributes)
      expect(json_response["variants"].first.keys).to include(*variants_attributes)
    end

    it "returns a 404 error when it cannot find a product" do
      api_get :show, id: "non-existant"

      expect(json_response["error"]).to eq("The resource you were looking for could not be found.")
      expect(response).to have_http_status(:not_found)
    end

    it "cannot create a new product if not an admin" do
      api_post :create, product: { name: "Brand new product!" }
      assert_unauthorized!
    end

    it "cannot update a product" do
      api_put :update, id: product.to_param, product: { name: "I hacked your store!" }
      assert_unauthorized!
    end
  end

  context "as an administrator" do
    before do
      allow(current_api_user)
        .to receive(:admin?).and_return(true)
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
      expect(response).to have_http_status(:created)
      expect(Spree::Product.last.variants.first.price).to eq 123.45
    end

    it "cannot create a new product with invalid attributes" do
      api_post :create, product: {}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["error"]).to eq("Invalid resource. Please fix errors and try again.")
      errors = json_response["errors"]
      expect(errors.keys).to match_array([
                                           "name", "price", "primary_taxon_id",
                                           "supplier_id", "variant_unit"
                                         ])
    end

    it "can update a product" do
      api_put :update, id: product.to_param, product: { name: "New and Improved Product!" }

      expect(response).to have_http_status(:ok)
    end

    it "cannot update a product with an invalid attribute" do
      api_put :update, id: product.to_param, product: { name: "" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json_response["error"]).to eq("Invalid resource. Please fix errors and try again.")
      expect(json_response["errors"]["name"]).to eq(["can't be blank"])
    end
  end

  private

  def supplier_enterprise_user(enterprise)
    user = create(:user)
    user.enterprise_roles.create(enterprise:)
    user
  end

  def returned_product_ids
    json_response['products'].pluck(:id)
  end
end
