# frozen_string_literal: false

RSpec.describe Spree::Admin::ProductsController do
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

        expect(response).to have_http_status :ok
      end
    end

    describe "when variant attributes are missing" do
      it 'renders form with errors' do
        spree_post :create, product: product_attrs.merge!(
          { supplier_id: nil, primary_taxon_id: nil }
        ),
                            button: 'create'
        expect(response).to have_http_status :ok
        expect(response).to render_template('spree/admin/products/new')
      end
    end
  end

  describe "updating a product" do
    let(:producer) { create(:enterprise) }
    let!(:product) { create(:simple_product, supplier_id: producer.id) }

    before do
      controller_login_as_enterprise_user [producer]
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
            expect(property_names).not_to include 'a different name'
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
