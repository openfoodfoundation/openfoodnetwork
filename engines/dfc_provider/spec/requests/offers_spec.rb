# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Offers", swagger_doc: "dfc.yaml" do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) { create(:distributor_enterprise, id: 10_000, owner: user) }
  let!(:product) {
    create(
      :product,
      id: 90_000,
      name: "Pesto", description: "Basil Pesto",
      variants: [variant],
    )
  }
  let(:variant) { build(:base_variant, id: 10_001, unit_value: 1, supplier: enterprise) }

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

    put "Update Offer" do
      consumes "application/json"

      parameter name: :offer, in: :body, schema: {
        example: {
          '@context': "https://www.datafoodconsortium.org",
          '@id': "http://test.host/api/dfc/enterprises/10000/offers/10001",
          '@type': "dfc-b:Offer",
          'dfc-b:hasPrice': 9.99,
          'dfc-b:stockLimitation': 7
        }
      }

      let(:id) { variant.id }
      let(:offer) { |example|
        example.metadata[:operation][:parameters].first[:schema][:example]
      }

      response "204", "success" do
        it "updates a variant" do |example|
          expect {
            submit_request(example.metadata)
            variant.reload
          }.to change { variant.price }.to(9.99)
            .and change { variant.on_hand }.to(7)
        end
      end
    end
  end
end
