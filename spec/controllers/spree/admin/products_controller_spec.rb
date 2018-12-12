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
        login_as_enterprise_user [s_managed]
        spree_post :bulk_update, {
          "products" => [{"id" => product.id, "name" => "Pine nuts"}]
        }
      end

      it "denies access" do
        response.should redirect_to spree.unauthorized_url
      end

      it "does not update any product" do
        product.reload.name.should_not == "Pine nuts"
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

      before { login_as_enterprise_user([producer]) }

      it 'fails' do
        spree_post :bulk_update, {
          "products" => [
            {
              "id" => product.id,
              "variant_unit" => "weight",
              "variant_unit_scale" => 1
            }
          ]
        }

        expect(response).to have_http_status(400)
      end

      it 'does not redirect to bulk_products' do
        spree_post :bulk_update, {
          "products" => [
            {
              "id" => product.id,
              "variant_unit" => "weight",
              "variant_unit_scale" => 1
            }
          ]
        }

        expect(response).not_to redirect_to(
          '/api/products/bulk_products?page=1;per_page=500;'
        )
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
      login_as_admin
      create(:stock_location)
    end

    it "redirects to products when the user hits 'create'" do
      spree_post :create, { product: product_attrs, button: 'create' }
      response.should redirect_to spree.admin_products_path
    end

    it "redirects to new when the user hits 'add_another'" do
      spree_post :create, { product: product_attrs, button: 'add_another' }
      response.should redirect_to spree.new_admin_product_path
    end
  end

  describe "updating" do
    describe "product properties" do
      context "as an enterprise user" do
        let(:producer) { create(:enterprise) }
        let!(:product) { create(:simple_product, supplier: producer) }
        let!(:property) { create(:property, name: "A nice name") }

        before do
          @request.env['HTTP_REFERER'] = 'http://test.com/'
          login_as_enterprise_user [producer]
        end

        context "when a submitted property does not already exist" do
          it "does not create a new property, or product property" do
            spree_put :update, {
              id: product,
              product: {
                product_properties_attributes: {
                  '0' => { property_name: 'a different name', value: 'something' }
                }
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
            spree_put :update, {
              id: product,
              product: {
                product_properties_attributes: {
                  '0' => { property_name: 'A nice name', value: 'something' }
                }
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
