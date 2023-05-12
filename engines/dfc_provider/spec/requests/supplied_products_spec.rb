# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe "SuppliedProducts", type: :request do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) { create(:distributor_enterprise, owner: user) }
  let!(:product) { create(:simple_product, supplier: enterprise ) }
  let!(:variant) { product.variants.first }

  describe :show do
    it "returns variants" do
      get enterprise_supplied_product_path(
        variant.id, enterprise_id: enterprise.id
      ), headers: auth_header(user.uid)

      expect(response).to have_http_status :ok
      expect(response.body).to include variant.name
    end

    it "doesn't find unrelated variants" do
      other_variant = create(:variant)

      get enterprise_supplied_product_path(
        other_variant.id, enterprise_id: enterprise.id
      ), headers: auth_header(user.uid)

      expect(response).to have_http_status :not_found
    end
  end

  describe :update do
    it "requires authorisation" do
      put enterprise_supplied_product_path(
        variant.id, enterprise_id: enterprise.id
      ), headers: {}

      expect(response).to have_http_status :unauthorized
    end

    it "updates a variant's attributes" do
      params = { enterprise_id: enterprise.id, id: variant.id }
      request_body = DfcProvider::Engine.root.join("spec/support/patch_supplied_product.json").read

      expect {
        put(
          enterprise_supplied_product_path(params),
          params: request_body,
          headers: auth_header(user.uid)
        )
        expect(response).to have_http_status :success
        variant.reload
      }.to change { variant.description }.to("DFC-Pesto updated")
    end
  end
end
