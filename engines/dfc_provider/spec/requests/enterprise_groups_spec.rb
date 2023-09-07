# frozen_string_literal: true

require_relative "../swagger_helper"

describe "EnterpriseGroups", type: :request, swagger_doc: "dfc.yaml", rswag_autodoc: true do
  let(:user) { create(:oidc_user, id: 12_345) }
  let(:group) {
    create(
      :enterprise_group,
      id: 60_000, owner: user, name: "Sustainable Farmers",
      enterprises: [enterprise],
    )
  }
  let(:enterprise) { create(:enterprise, id: 10_000) }

  before { login_as user }

  path "/api/dfc/enterprise_groups" do
    get "List groups" do
      produces "application/json"

      response "200", "successful" do
        let!(:groups) { [group] }

        run_test! do
          graph = json_response["@graph"]

          expect(graph[0]["@type"]).to eq "dfc-b:Person"
          expect(graph[0]).to include(
            "dfc-b:affiliates" => "http://test.host/api/dfc/enterprise_groups/60000",
          )

          expect(graph[1]["@type"]).to eq "dfc-b:Enterprise"
          expect(graph[1]).to include(
            "dfc-b:hasName" => "Sustainable Farmers",
            "dfc-b:affiliatedBy" => "http://test.host/api/dfc/enterprises/10000",
          )
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
          expect(json_response).to include(
            "dfc-b:hasName" => "Sustainable Farmers",
            "dfc-b:affiliatedBy" => "http://test.host/api/dfc/enterprises/10000",
          )
        end
      end
    end
  end
end
