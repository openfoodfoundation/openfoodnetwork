# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe "SuppliedProducts", type: :request do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) { create(:distributor_enterprise, owner: user) }
  let!(:product) { create(:simple_product, supplier: enterprise ) }
  let!(:variant) { product.variants.first }

  describe :create do
    let(:endpoint) do
      enterprise_supplied_products_path(enterprise_id: enterprise.id)
    end
    let(:supplied_product) do
      SuppliedProductBuilder.supplied_product(new_variant)
    end
    let(:new_variant) do
      # We need an id to generate a URL as semantic id when exporting.
      build(:variant, id: 0, name: "Apple", unit_value: 3)
    end

    it "flags a bad request" do
      post endpoint, headers: auth_header(user.uid)

      expect(response).to have_http_status :bad_request
    end

    it "creates a variant" do
      request_body = DfcLoader.connector.export(supplied_product)

      expect do
        post endpoint,
             params: request_body,
             headers: auth_header(user.uid)
      end
        .to change { enterprise.supplied_products.count }.by(1)

      variant = Spree::Variant.last
      expect(variant.name).to eq "Apple"
      expect(variant.unit_value).to eq 3
    end
  end

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
        .and change { variant.unit_value }.to(17)
    end
  end
end
