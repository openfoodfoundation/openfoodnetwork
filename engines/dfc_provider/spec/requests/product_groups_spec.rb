# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "ProductGroups", swagger_doc: "dfc.yaml" do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) { create(:distributor_enterprise, id: 10_000, owner: user) }
  let!(:product) {
    create(
      :product_with_image,
      id: 90_000,
      name: "Pesto", description: "Basil Pesto",
      variants: [variant]
    )
  }
  let(:Authorization) { nil }
  let(:variant) {
    build(:base_variant, id: 10_001, unit_value: 1, primary_taxon: taxon, supplier: enterprise)
  }
  let(:taxon) {
    build(
      :taxon,
      name: "Processed Vegetable",
      dfc_id: "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#processed-vegetable"
    )
  }

  before { login_as user }

  path "/api/dfc/product_groups/{id}" do
    parameter name: :enterprise_id, in: :path, type: :string
    parameter name: :id, in: :path, type: :string

    let(:enterprise_id) { enterprise.id }

    get "Show ProductGroup" do
      produces "application/json"
      security [oidc_token: []]

      response "200", "success" do
        let(:id) { product.id }

        context "as platform user" do
          include_context "authenticated as platform"

          before {
            DfcPermission.create!(
              user:, enterprise_id:,
              scope: "ReadEnterprise", grantee: "cqcm-dev",
            )
            DfcPermission.create!(
              user:, enterprise_id:,
              scope: "ReadProducts", grantee: "cqcm-dev",
            )
          }

          run_test!
        end

        run_test! do
          expect(json_response["@id"]).to eq "http://test.host/api/dfc/product_groups/90000"

          expect(json_response["dfc-b:hasVariant"]).to eq "http://test.host/api/dfc/enterprises/10000/supplied_products/10001"
        end
      end
    end
  end
end
