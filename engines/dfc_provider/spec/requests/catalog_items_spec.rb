# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe "CatalogItems", type: :request do
  let(:user) { create(:oidc_user) }
  let(:enterprise) { create(:distributor_enterprise, owner: user) }
  let(:product) { create(:simple_product, supplier: enterprise ) }
  let(:variant) { product.variants.first }

  describe :index do
    it "returns not_found without enterprise" do
      items_path = enterprise_catalog_items_path(enterprise_id: "default")

      get items_path, headers: auth_header(user.uid)

      expect(response).to have_http_status :not_found
    end

    context "with existing variant" do
      before { variant }
      it "lists catalog items with offers of default enterprise" do
        items_path = enterprise_catalog_items_path(enterprise_id: "default")

        get items_path, headers: auth_header(user.uid)

        expect(response).to have_http_status :ok
        expect(response.body).to include variant.name
        expect(response.body).to include variant.sku
        expect(response.body).to include "offers/#{variant.id}"
      end

      it "lists catalog items with offers of requested enterprise" do
        items_path = enterprise_catalog_items_path(enterprise_id: enterprise.id)

        get items_path, headers: auth_header(user.uid)

        expect(response).to have_http_status :ok
        expect(response.body).to include variant.name
        expect(response.body).to include variant.sku
        expect(response.body).to include "offers/#{variant.id}"
      end

      it "returns not_found for unrelated enterprises" do
        other_enterprise = create(:enterprise)
        items_path = enterprise_catalog_items_path(enterprise_id: other_enterprise.id)

        get items_path, headers: auth_header(user.uid)

        expect(response).to have_http_status :not_found
      end

      it "returns unauthorized for unauthenticated users" do
        items_path = enterprise_catalog_items_path(enterprise_id: "default")

        get items_path, headers: {}

        expect(response).to have_http_status :unauthorized
      end

      it "recognises app user sessions as logins" do
        items_path = enterprise_catalog_items_path(enterprise_id: "default")
        login_as user

        get items_path, headers: {}

        expect(response).to have_http_status :ok
      end
    end
  end

  describe :show do
    it "returns a catalog item with offer" do
      item_path = enterprise_catalog_item_path(
        variant,
        enterprise_id: enterprise.id
      )

      get item_path, headers: auth_header(user.uid)

      expect(response).to have_http_status :ok
      expect(response.body).to include "dfc-b:CatalogItem"
      expect(response.body).to include "offers/#{variant.id}"
    end

    it "returns not_found for unrelated variant" do
      item_path = enterprise_catalog_item_path(
        create(:variant),
        enterprise_id: enterprise.id
      )

      get item_path, headers: auth_header(user.uid)

      expect(response).to have_http_status :not_found
    end
  end
end
