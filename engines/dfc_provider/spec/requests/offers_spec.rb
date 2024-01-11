# frozen_string_literal: true

require_relative "../swagger_helper"

describe "Offers", type: :request, swagger_doc: "dfc.yaml", rswag_autodoc: true do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) { create(:distributor_enterprise, id: 10_000, owner: user) }
  let!(:product) {
    create(
      :product,
      id: 90_000,
      supplier: enterprise, name: "Pesto", description: "Basil Pesto",
      variants: [variant],
    )
  }
  let(:variant) { build(:base_variant, id: 10_001, unit_value: 1) }

  before { login_as user }

  path "/api/dfc/enterprises/{enterprise_id}/offers/{id}" do
    parameter name: :enterprise_id, in: :path, type: :string
    parameter name: :id, in: :path, type: :string

    let(:enterprise_id) { enterprise.id }

    get "Show Offer" do
      produces "application/json"

      response "200", "success" do
        let(:id) { variant.id }

        run_test!
      end
    end
  end
end
