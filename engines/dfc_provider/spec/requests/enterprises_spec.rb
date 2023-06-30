# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/swagger_helper")

describe "Enterprises", type: :request, swagger_doc: "dfc-v1.7/swagger.yaml", rswag_autodoc: true do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) { create(:distributor_enterprise, id: 10_000, owner: user) }
  let!(:product) {
    create(
      :base_product,
      supplier: enterprise, name: "Apple", description: "Round",
      variants: [variant],
    )
  }
  let(:variant) { build(:base_variant, id: 10_001, unit_value: 1, sku: "APP") }

  before { login_as user }

  path "/api/dfc-v1.7/enterprises/{id}" do
    get "Show enterprise" do
      parameter name: :id, in: :path, type: :string
      produces "application/json"

      response "200", "successful" do
        context "without enterprise id" do
          let(:id) { "default" }

          run_test! do
            expect(response.body).to include("Apple")
            expect(response.body).to include("APP")
            expect(response.body).to include("offers/10001")
          end
        end

        context "given an enterprise id" do
          let(:id) { enterprise.id }

          run_test! do
            expect(response.body).to include "Apple"
          end
        end
      end

      response "404", "not found" do
        let(:id) { other_enterprise.id }
        let(:other_enterprise) { create(:distributor_enterprise) }

        run_test! do
          expect(response.body).to_not include "Apple"
        end
      end
    end
  end
end
