require 'spec_helper'

describe Spree::Admin::ProductsController, type: :controller do
  describe "updating a product we do not have access to" do
    let(:s_managed) { create(:enterprise) }
    let(:s_unmanaged) { create(:enterprise) }
    let(:p) { create(:simple_product, supplier: s_unmanaged, name: 'Peas') }

    before do
      login_as_enterprise_user [s_managed]
      spree_post :bulk_update, {"products" => [{"id" => p.id, "name" => "Pine nuts"}]}
    end

    it "denies access" do
      response.should redirect_to spree.unauthorized_url
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
