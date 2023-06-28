# frozen_string_literal: true

require 'spec_helper'

describe Api::V0::VariantsController, type: :controller do
  render_views

  let(:supplier) { create(:supplier_enterprise) }
  let!(:variant1) { create(:variant) }
  let!(:variant2) { create(:variant) }
  let!(:variant3) { create(:variant) }
  let(:attributes) {
    [:id, :options_text, :price, :on_hand, :unit_value, :unit_description, :on_demand, :display_as,
     :display_name]
  }

  before do
    allow(controller).to receive(:spree_current_user) { current_api_user }
  end

  context "as a normal user" do
    let(:current_api_user) { build(:user) }

    let!(:product) { create(:product) }
    let!(:variant) { product.variants.first }

    it "retrieves a list of variants with appropriate attributes" do
      get :index, format: :json

      keys = json_response.first.keys.map(&:to_sym)
      expect(attributes.all?{ |attr| keys.include? attr }).to eq(true)
    end

    it 'can query the results through a parameter' do
      expected_result = create(:variant, sku: 'FOOBAR')
      api_get :index, q: { sku_cont: 'FOO' }

      expect(json_response.size).to eq(1)
      expect(json_response.first['sku']).to eq expected_result.sku
    end

    # Regression test for spree#2141
    context "a deleted variant" do
      before do
        expect(Spree::Variant.count).to eq 7
        variant.update_column(:deleted_at, Time.zone.now)
      end

      it "is not returned in the results" do
        api_get :index
        expect(json_response.count).to eq(6)
      end

      it "is not returned even when show_deleted is passed" do
        api_get :index, show_deleted: true
        expect(json_response.count).to eq(6)
      end
    end

    it "can see a single variant" do
      api_get :show, id: variant.to_param

      keys = json_response.keys.map(&:to_sym)
      expect(attributes.all?{ |attr| keys.include? attr }).to eq(true)
    end

    it "cannot create a new variant if not an admin" do
      api_post :create, variant: { sku: "12345" }

      assert_unauthorized!
    end

    it "cannot update a variant" do
      api_put :update, id: variant.to_param, variant: { sku: "12345" }

      assert_unauthorized!
    end

    it "cannot delete a variant" do
      api_delete :destroy, id: variant.to_param

      assert_unauthorized!
      expect { variant.reload }.not_to raise_error
      expect(variant.deleted_at).to be_nil
    end
  end

  context "as an enterprise user" do
    let(:current_api_user) { create(:user, enterprises: [supplier]) }
    let(:supplier_other) { create(:supplier_enterprise) }
    let!(:product) { create(:product, supplier: supplier) }
    let(:variant) { product.variants.first }
    let(:product_other) { create(:product, supplier: supplier_other) }
    let(:variant_other) { product_other.variants.first }

    context "with a single remaining variant" do
      it "does not delete the variant" do
        api_delete :destroy, id: variant.id

        expect(variant.reload.deleted_at).to be_nil
      end
    end

    context "with more than one variants" do
      let(:variant_to_delete) { create(:variant, product: product) }

      it "deletes a variant" do
        api_delete :destroy, id: variant_to_delete.id

        expect(response.status).to eq(204)
        expect { variant_to_delete.reload }.not_to raise_error
        expect(variant_to_delete.deleted_at).to be_present
      end

      it "is denied access to soft deleting another enterprises' variant" do
        api_delete :destroy, id: variant_other.to_param

        assert_unauthorized!
        expect { variant_other.reload }.not_to raise_error
        expect(variant_other.deleted_at).to be_nil
      end
    end
  end

  context "as an administrator" do
    let(:current_api_user) { create(:admin_user) }

    let(:product) { create(:product) }
    let(:variant) { product.variants.first }
    let!(:variant2) { create(:variant, product: product) }

    context "deleted variants" do
      before do
        variant.update_column(:deleted_at, Time.zone.now)
      end

      it "are visible by admin" do
        api_get :index, show_deleted: 1, product_id: variant.product.id

        expect(json_response.count).to eq(2)
      end
    end

    it "can create a new variant" do
      original_number_of_variants = variant.product.variants.count
      api_post :create, variant: { sku: "12345", unit_value: "1",
                                   unit_description: "L", price: "1" },
                        product_id: variant.product.id

      expect(attributes.all?{ |attr| json_response.include? attr.to_s }).to eq(true)
      expect(response.status).to eq(201)
      expect(json_response["sku"]).to eq("12345")
      expect(variant.product.variants.count).to eq(original_number_of_variants + 1)
    end

    it "can update a variant" do
      api_put :update, id: variant.to_param, variant: { sku: "12345" }

      expect(response.status).to eq(200)
    end

    it "can delete a variant" do
      api_delete :destroy, id: variant.to_param

      expect(response.status).to eq(204)
      expect { variant.reload }.not_to raise_error
      expect(variant.deleted_at).not_to be_nil
    end

    it "doesn't delete the only variant of the product" do
      product = create(:product)
      variant = product.variants.first
      spree_delete :destroy, id: variant.to_param

      expect(variant.reload).to_not be_deleted
      expect(assigns(:variant).errors[:product]).to include "must have at least one variant"
    end
  end
end
