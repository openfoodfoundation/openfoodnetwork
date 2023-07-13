# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/swagger_helper")

describe "CatalogItems", type: :request, swagger_doc: "dfc-v1.7/swagger.yaml",
                         rswag_autodoc: true do
  let(:user) { create(:oidc_user, id: 12_345) }
  let(:enterprise) { create(:distributor_enterprise, id: 10_000, owner: user) }
  let(:product) {
    create(
      :base_product,
      supplier: enterprise, name: "Apple", description: "Red",
      variants: [variant],
    )
  }
  let(:variant) { build(:base_variant, id: 10_001, unit_value: 1, sku: "AR") }

  before { login_as user }

  path "/api/dfc-v1.7/enterprises/{enterprise_id}/catalog_items" do
    parameter name: :enterprise_id, in: :path, type: :string

    get "List CatalogItems" do
      produces "application/json"

      response "404", "not found" do
        context "without enterprises" do
          let(:enterprise_id) { "default" }

          run_test!
        end

        context "with unrelated enterprise" do
          let(:enterprise_id) { create(:enterprise).id }

          run_test!
        end
      end

      response "200", "success" do
        before { product }

        context "with default enterprise id" do
          let(:enterprise_id) { "default" }

          run_test! do
            expect(response.body).to include "Apple"
            expect(response.body).to include "AR"
            expect(response.body).to include "offers/10001"
          end
        end

        context "with given enterprise id" do
          let(:enterprise_id) { 10_000 }

          run_test! do
            expect(response.body).to include "Apple"
            expect(response.body).to include "AR"
            expect(response.body).to include "offers/10001"
          end
        end
      end

      response "401", "unauthorized" do
        let(:enterprise_id) { "default" }

        before { login_as nil }

        run_test!
      end
    end
  end

  path "/api/dfc-v1.7/enterprises/{enterprise_id}/catalog_items/{id}" do
    parameter name: :enterprise_id, in: :path, type: :string
    parameter name: :id, in: :path, type: :string

    get "Show CatalogItem" do
      produces "application/json"

      before { product }

      response "200", "success" do
        let(:enterprise_id) { 10_000 }
        let(:id) { 10_001 }

        run_test! do
          expect(response.body).to include "dfc-b:CatalogItem"
          expect(response.body).to include "offers/10001"
        end
      end

      response "404", "not found" do
        let(:enterprise_id) { 10_000 }
        let(:id) { create(:variant).id }

        run_test!
      end
    end

    put "Update CatalogItem" do
      consumes "application/json"

      parameter name: :catalog_item, in: :body, schema: {
        example: ExampleJson.read("patch_catalog_item")
      }

      before { product }

      response "204", "no content" do
        let(:enterprise_id) { 10_000 }
        let(:id) { 10_001 }
        let(:catalog_item) do |example|
          example.metadata[:operation][:parameters].first[:schema][:example]
        end

        it "updates a variant" do |example|
          expect {
            submit_request(example.metadata)
            variant.reload
          }.to change { variant.on_hand }.to(3)
            .and change { variant.sku }.to("new-sku")
        end
      end
    end
  end
end
