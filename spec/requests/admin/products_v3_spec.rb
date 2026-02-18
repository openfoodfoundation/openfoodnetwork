# frozen_string_literal: true

RSpec.describe "Admin::ProductsV3" do
  include AuthenticationHelper

  let(:user) { create(:user) }
  let(:headers) { { Accept: "text/vnd.turbo-stream.html" } }
  let(:product) { create(:simple_product, supplier_id: create(:supplier_enterprise).id) }

  before do
    login_as user
  end

  describe "DELETE /admin/product_v3/:id" do
    it "checks for permission" do
      delete(admin_product_destroy_path(product), headers: )

      expect(response).to redirect_to('/unauthorized')
    end
  end

  describe "POST /admin/clone/:id" do
    it "checks for permission" do
      post(admin_clone_product_path(product), headers: )

      expect(response).to redirect_to('/unauthorized')
    end
  end

  describe "DELETE /admin/product_v3/destroy_variant/:id" do
    it "checks for permission" do
      delete(admin_destroy_variant_path(product.variants.first), headers: )

      expect(response).to redirect_to('/unauthorized')
    end
  end

  describe "POST /admin/products/bulk_update" do
    it "checks for permission" do
      variant = product.variants.first

      params = {
        products: {
          '0': {
            id: product.id,
            name: "Updated product name",
            variants_attributes: {
              '0': {
                id: variant.id,
                display_name: "Updated variant display name",
              }
            }
          }
        }
      }

      post(admin_products_bulk_update_path, params:, headers: )

      expect(response).to redirect_to('/unauthorized')
    end
  end
end
