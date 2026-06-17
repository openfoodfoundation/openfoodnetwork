# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "EnterpriseGroups", swagger_doc: "dfc.yaml" do
  let(:Accept) { "application/json" }
  let(:user) { create(:oidc_user, id: 12_345) }
  let(:group) {
    create(
      :enterprise_group,
      id: 60_000, owner: user, name: "Sustainable Farmers", address:,
      enterprises: [enterprise1, enterprise2],
    )
  }
  let(:address) { create(:address, id: 40_000, address1: "8 Acres Drive") }
  let(:enterprise1) { create(:enterprise, id: 10_001) }
  let(:enterprise2) { create(:enterprise, id: 10_002) }

  before { login_as user }

  path "/api/dfc/enterprise_groups" do
    get "List groups" do
      produces "application/json", 'application/ld+json; profile="dfc-v2"'

      response "200", "successful" do
        let!(:groups) { [group] }

        context "in DFC v1 format" do
          run_test! do
            expect(subject["@type"]).to eq "dfc-b:Enterprise"
            expect(subject).to include(
              "@id" => "http://test.host/api/dfc/enterprise_groups/60000",
              "dfc-b:name" => "Sustainable Farmers",
              "dfc-b:affiliatedBy" => [
                "http://test.host/api/dfc/enterprises/10001",
                "http://test.host/api/dfc/enterprises/10002",
              ],
            )
          end
        end

        context "in DFC v2 format" do
          let(:Accept) { 'application/ld+json; profile="dfc-v2"' }

          run_test! do
            expect(graph[0]).to include(
              "@id" => "http://test.host/api/dfc/enterprise_groups",
              "@type" => "ldp:Container",
              "ldp:contains" => "http://test.host/api/dfc/enterprise_groups/60000",
            )
            expect(graph[1]).to include(
              "@id" => "http://test.host/api/dfc/enterprise_groups/60000",
              "@type" => "dfc-b:Enterprise",
              "dfc-b:name" => "Sustainable Farmers",
              "dfc-b:affiliatedBy" => [
                "http://test.host/api/dfc/enterprises/10001",
                "http://test.host/api/dfc/enterprises/10002",
              ],
            )
          end
        end
      end
    end
  end

  path "/api/dfc/enterprise_groups/{id}" do
    get "Show groups" do
      parameter name: :id, in: :path, type: :string
      produces "application/json"

      response "200", "successful" do
        let(:id) { group.id }

        run_test! do
          graph = json_response["@graph"]

          expect(graph[0]).to include(
            "@type" => "dfc-b:Enterprise",
            "dfc-b:name" => "Sustainable Farmers",
            "dfc-b:hasAddress" => "http://test.host/api/dfc/addresses/40000",
            "dfc-b:affiliatedBy" => [
              "http://test.host/api/dfc/enterprises/10001",
              "http://test.host/api/dfc/enterprises/10002",
            ],
          )

          expect(graph[1]).to include(
            "@type" => "dfc-b:Address",
            "dfc-b:hasStreet" => "8 Acres Drive",
          )
        end
      end
    end
  end
end
