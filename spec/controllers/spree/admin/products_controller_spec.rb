# frozen_string_literal: false

require 'spec_helper'

describe Spree::Admin::ProductsController, type: :controller do
  describe 'bulk_update' do
    context "updating a product we do not have access to" do
      let(:s_managed) { create(:enterprise) }
      let(:s_unmanaged) { create(:enterprise) }
      let(:product) do
        create(:simple_product, supplier: s_unmanaged, name: 'Peas')
      end

      before do
        controller_login_as_enterprise_user [s_managed]
        spree_post :bulk_update,
                   "products" => [{ "id" => product.id, "name" => "Pine nuts" }]
      end

      it "denies access" do
        expect(response).to redirect_to unauthorized_path
      end

      it "does not update any product" do
        expect(product.reload.name).not_to eq("Pine nuts")
      end
    end

    context "when changing a product's variant_unit" do
      let(:producer) { create(:enterprise) }
      let!(:product) do
        create(
          :simple_product,
          supplier: producer,
          variant_unit: 'items',
          variant_unit_scale: nil,
          variant_unit_name: 'bunches',
          unit_value: nil,
          unit_description: 'some description'
        )
      end

      before { controller_login_as_enterprise_user([producer]) }

      it 'succeeds' do
        spree_post :bulk_update,
                   "products" => [
                     {
                       "id" => product.id,
                       "variant_unit" => "weight",
                       "variant_unit_scale" => 1
                     }
                   ]

        expect(response).to have_http_status(302)
      end

      it 'does not redirect to bulk_products' do
        spree_post :bulk_update,
                   "products" => [
                     {
                       "id" => product.id,
                       "variant_unit" => "weight",
                       "variant_unit_scale" => 1
                     }
                   ]

        expect(response).to redirect_to(
          '/api/v0/products/bulk_products'
        )
      end
    end

    context 'when passing empty variants_attributes' do
      let(:producer) { create(:enterprise) }
      let!(:product) do
        create(
          :simple_product,
          supplier: producer,
          variant_unit: 'items',
          variant_unit_scale: nil,
          variant_unit_name: 'bunches',
          unit_value: nil,
          unit_description: 'bunches'
        )
      end
      let!(:another_product) do
        create(
          :simple_product,
          supplier: producer,
          variant_unit: 'weight',
          variant_unit_scale: 1000,
          variant_unit_name: nil
        )
      end

      before { controller_login_as_enterprise_user([producer]) }

      it 'does not fail' do
        spree_post :bulk_update,
                   "products" => [
                     {
                       "id" => another_product.id,
                       "variants_attributes" => [{}]
                     },
                     {
                       "id" => product.id,
                       "variants_attributes" => [
                         {
                           "on_hand" => 2,
                           "price" => "5.0",
                           "unit_value" => 4,
                           "unit_description" => "",
                           "display_name" => "name"
                         }
                       ]
                     }
                   ]

        expect(response).to have_http_status(:found)
      end
    end
  end

  context "creating a new product" do
    let(:supplier) { create(:supplier_enterprise) }
    let(:taxon) { create(:taxon) }
    let(:shipping_category) { create(:shipping_category) }

    let(:product_attrs) {
      attributes_for(:product).merge(
        shipping_category_id: shipping_category.id,
        supplier_id: supplier.id,
        primary_taxon_id: taxon.id
      )
    }

    before do
      controller_login_as_admin
      create(:stock_location)
    end

    it "redirects to products when the user hits 'create'" do
      spree_post :create, product: product_attrs, button: 'create'
      expect(response).to redirect_to spree.admin_products_path
    end

    it "redirects to new when the user hits 'add_another'" do
      spree_post :create, product: product_attrs, button: 'add_another'
      expect(response).to redirect_to spree.new_admin_product_path
    end

    describe "when user uploads an image in an unsupported format" do
      it "does not throw an exception" do
        product_image = ActionDispatch::Http::UploadedFile.new(
          filename: 'unsupported_image_format.exr',
          content_type: 'application/octet-stream',
          tempfile: Tempfile.new('unsupported_image_format.exr')
        )
        product_attrs_with_image = product_attrs.merge(
          image_attributes: {
            attachment: product_image
          }
        )

        spree_put :create, product: product_attrs_with_image

        expect(response.status).to eq 200
      end
    end
  end

  describe "updating a product" do
    let(:producer) { create(:enterprise) }
    let!(:product) { create(:simple_product, supplier: producer) }

    before do
      controller_login_as_enterprise_user [producer]
    end

    describe "change product supplier" do
      let(:distributor) { create(:distributor_enterprise) }
      let!(:order_cycle) {
        create(:simple_order_cycle, variants: [product.variants.first], coordinator: distributor,
                                    distributors: [distributor])
      }

      it "should remove product from existing Order Cycles" do
        new_producer = create(:enterprise)
        spree_put :update, id: product, product: { supplier_id: new_producer.id }

        expect(product.reload.supplier.id).to eq new_producer.id
        expect(order_cycle.reload.distributed_variants).to_not include product.variants.first
      end
    end

    describe "product stock setting with errors" do
      it "notifies bugsnag and still raise error" do
        # forces an error in the variant
        product.variants.first.stock_items = []

        expect(Bugsnag).to receive(:notify)

        expect do
          spree_put :update,
                    id: product,
                    product: {
                      on_hand: 1
                    }
        end.to raise_error(StandardError)
      end
    end

    describe "product properties" do
      context "as an enterprise user" do
        let!(:property) { create(:property, name: "A nice name") }

        context "when a submitted property does not already exist" do
          it "does not create a new property, or product property" do
            spree_put :update,
                      id: product,
                      product: {
                        product_properties_attributes: {
                          '0' => { property_name: 'a different name', value: 'something' }
                        }
                      }
            expect(Spree::Property.count).to be 1
            expect(Spree::ProductProperty.count).to be 0
            property_names = product.reload.properties.map(&:name)
            expect(property_names).to_not include 'a different name'
          end
        end

        context "when a submitted property exists" do
          it "adds a product property" do
            spree_put :update,
                      id: product,
                      product: {
                        product_properties_attributes: {
                          '0' => { property_name: 'A nice name', value: 'something' }
                        }
                      }
            expect(Spree::Property.count).to be 1
            expect(Spree::ProductProperty.count).to be 1
            property_names = product.reload.properties.map(&:name)
            expect(property_names).to include 'A nice name'
          end
        end
      end
    end
  end
end
