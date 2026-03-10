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

  describe "POST /admin/products/create_linked_variant" do
    let(:enterprise) { create(:supplier_enterprise) }
    let(:user) { create(:user, enterprises: [enterprise]) }

    let(:supplier) { create(:supplier_enterprise) }
    let(:variant) { create(:variant, display_name: "Original variant", supplier: supplier) }

    before do
      sign_in user
    end

    it "checks for permission" do
      params = { variant_id: variant.id, product_index: 1 }

      expect {
        post(admin_create_linked_variant_path, as: :turbo_stream, params:)
        expect(response).to redirect_to('/unauthorized')
      }.not_to change { variant.product.variants.count }
    end

    context "With create_linked_variants permissions on supplier" do
      let!(:enterprise_relationship) {
        create(:enterprise_relationship,
               parent: supplier,
               child: enterprise,
               permissions_list: [:create_linked_variants])
      }

      it "clones the variant, retaining link as source" do
        params = { variant_id: variant.id, product_index: 1 }

        expect {
          post(admin_create_linked_variant_path, as: :turbo_stream, params:)

          expect(response).to have_http_status(:ok)
          expect(response.body).to match "Original variant" # cloned variant name
        }.to change { variant.product.variants.count }.by(1)

        new_variant = variant.product.variants.order(:id).last
        # The new variant is a target of the original. It is a "sourced" variant.
        expect(variant.target_variants.first).to eq new_variant
        # The new variant's source is the original
        expect(new_variant.source_variants.first).to eq variant
      end

      context "and I'm also owner of another enterprise" do
        let!(:enterprise2) { create(:enterprise) }
        let(:user) { create(:user, enterprises: [enterprise, enterprise2]) }

        it "clones the variant, owned by my enterprise that has permission" do
          enterprise2.owner = user
          params = { variant_id: variant.id, product_index: 1 }

          expect {
            post(admin_create_linked_variant_path, as: :turbo_stream, params:)

            expect(response).to have_http_status(:ok)
          }.to change { variant.product.variants.count }.by(1)

          # The new variant is owned by my enterprise that has permission, not the other one
          new_variant = variant.product.variants.order(:id).last
          expect(new_variant.owner).to eq enterprise
        end
      end
    end
  end
end
