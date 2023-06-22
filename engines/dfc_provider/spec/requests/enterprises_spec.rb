# frozen_string_literal: true

require "swagger_helper"
require DfcProvider::Engine.root.join("spec/spec_helper")

describe "Enterprises", type: :request, swagger_doc: "dfc-v1.7/swagger.yaml" do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) { create(:distributor_enterprise, owner: user) }
  let!(:product) { create(:simple_product, supplier: enterprise ) }

  before { login_as user }

  path "/api/dfc-v1.7/enterprises/{id}" do
    get "Show enterprise" do
      parameter name: :id, in: :path, type: :string
      produces "application/json"

      response "200", "successful" do
        context "without enterprise id" do
          let(:id) { "default" }

          run_test! do
            expect(response.body).to include(product.name)
            expect(response.body).to include(product.variants.first.sku)
            expect(response.body).to include("offers/#{product.variants.first.id}")
          end
        end

        context "given an enterprise id" do
          let(:id) { enterprise.id }

          run_test! do
            expect(response.body).to include(product.name)
          end
        end
      end

      response "404", "not found" do
        let(:id) { other_enterprise.id }
        let(:other_enterprise) { create(:distributor_enterprise) }

        run_test! do
          expect(response.body).to_not include(product.name)
        end
      end
    end
  end
end
