# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Addresses", swagger_doc: "dfc.yaml" do
  let(:user) { create(:oidc_user) }
  let(:address) { create(:address, id: 40_000) }
  let(:Accept) { "application/json" }

  before { login_as user }

  path "/api/dfc/addresses/{id}" do
    get "Show address" do
      parameter name: :id, in: :path, type: :string
      parameter name: :Accept, in: :header, type: :string
      produces "application/json", 'application/ld+json; profile="dfc-v2"'

      response "200", "successful" do
        let(:id) { address.id }

        before { create(:enterprise, owner: user, address:) }

        context "in DFC v1 format" do
          run_test! do
            expect(subject["@context"]).to eq "https://w3id.org/dfc/ontology/context/context_1.16.0.json"
            expect(subject["@id"]).to eq "http://test.host/api/dfc/addresses/40000"
            expect(subject["@type"]).to eq "dfc-b:Address"
          end
        end

        context "in DFC v2 format" do
          let(:Accept) { 'application/ld+json; profile="dfc-v2"' }

          run_test! do
            expect(subject["@context"]).to eq "https://w3id.org/dfc/ontology/context/context_2.0.0.json"
            expect(subject["@id"]).to eq "http://test.host/api/dfc/addresses/40000"
            expect(subject["@type"]).to eq "dfc-b:Address"
          end
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
