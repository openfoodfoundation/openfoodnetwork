# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe "Enterprises", type: :request do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) { create(:distributor_enterprise, owner: user) }
  let!(:product) { create(:simple_product, supplier: enterprise ) }

  describe :show do
    it "returns the default enterprise" do
      get enterprise_path("default"), headers: auth_header(user.uid)

      expect(response).to have_http_status :ok
      expect(response.body).to include(product.name)
      expect(response.body).to include(product.variants.first.sku)
      expect(response.body).to include("offers/#{product.variants.first.id}")
    end

    it "returns the requested enterprise" do
      get enterprise_path(enterprise.id), headers: auth_header(user.uid)

      expect(response).to have_http_status :ok
      expect(response.body).to include(product.name)
    end

    it "returns not found for unrelated enterprise" do
      other_enterprise = create(:distributor_enterprise)
      get enterprise_path(other_enterprise.id), headers: auth_header(user.uid)

      expect(response).to have_http_status :not_found
      expect(response.body).to_not include(product.name)
    end
  end
end
