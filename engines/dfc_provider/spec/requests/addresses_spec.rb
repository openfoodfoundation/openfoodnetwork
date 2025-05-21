# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Addresses", swagger_doc: "dfc.yaml" do
  let(:user) { create(:oidc_user) }
  let(:address) { create(:address, id: 40_000) }
  let(:result) { json_response }

  before { login_as user }

  path "/api/dfc/addresses/{id}" do
    get "Show address" do
      parameter name: :id, in: :path, type: :string
      produces "application/json"

      response "200", "successful" do
        let(:id) { address.id }

        before { create(:enterprise, owner: user, address:) }

        run_test! do
          expect(result["@id"]).to eq "http://test.host/api/dfc/addresses/40000"
          expect(result["@type"]).to eq "dfc-b:Address"
        end
      end

      response "404", "not found" do
        context "when the address doesn't exist" do
          let(:id) { 0 }
          run_test!
        end

        context "when the address doesn't belong to you" do
          let(:id) { address.id }
          run_test!
        end
      end
    end
  end
end
