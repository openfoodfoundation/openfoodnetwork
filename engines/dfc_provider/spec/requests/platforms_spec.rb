# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Platforms", swagger_doc: "dfc.yaml" do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) do
    create(
      :distributor_enterprise,
      id: 10_000, owner: user, name: "Fred's Farm",
    )
  end

  before { login_as user }

  path "/api/dfc/enterprises/{enterprise_id}/platforms" do
    parameter name: :enterprise_id, in: :path, type: :string

    get "List platforms with scopes" do
      produces "application/json"

      response "200", "successful" do
        let(:enterprise_id) { enterprise.id }

        run_test! do
          expect(json_response["@id"]).to eq "http://test.host/api/dfc/enterprises/10000/platforms"
        end
      end
    end
  end

  path "/api/dfc/enterprises/{enterprise_id}/platforms/{platform_id}" do
    parameter name: :enterprise_id, in: :path, type: :string
    parameter name: :platform_id, in: :path, type: :string

    put "Update authorized scopes of a platform" do
      consumes "application/json"
      produces "application/json"

      parameter name: :platform, in: :body, schema: {
        example: {
          '@context': "https://cdn.startinblox.com/owl/context-bis.jsonld",
          '@id': "/api/dfc/enterprises/3/platforms/682b2e2b031c28f69cda1645",
          'dfc-t:hasAssignedScopes': {
            '@list': [
              {
                '@id': "/api/dfc/enterprises/3/platforms/scopes/ReadEnterprise",
                'dfc-t:scope': "ReadEnterprise",
                '@type': "dfc-t:Scope"
              },
              {
                '@id': "/api/dfc/enterprises/3/platforms/scopes/WriteEnterprise",
                'dfc-t:scope': "WriteEnterprise",
                '@type': "dfc-t:Scope"
              },
              {
                '@id': "/api/dfc/enterprises/3/platforms/scopes/ReadProducts",
                'dfc-t:scope': "ReadProducts",
                '@type': "dfc-t:Scope"
              },
              {
                '@id': "/api/dfc/enterprises/3/platforms/scopes/WriteProducts",
                'dfc-t:scope': "WriteProducts",
                '@type': "dfc-t:Scope"
              },
              {
                '@id': "/api/dfc/enterprises/3/platforms/scopes/ReadOrders",
                'dfc-t:scope': "ReadOrders",
                '@type': "dfc-t:Scope"
              },
              {
                '@id': "/api/dfc/enterprises/3/platforms/scopes/WriteOrders",
                'dfc-t:scope': "WriteOrders",
                '@type': "dfc-t:Scope"
              }
            ],
            '@type': "rdf:List"
          }
        }
      }

      response "200", "successful" do
        let(:enterprise_id) { enterprise.id }
        let(:platform_id) { "682b2e2b031c28f69cda1645" }
        let(:platform) do |example|
          example.metadata[:operation][:parameters].first[:schema][:example]
        end

        run_test! do
          expect(json_response["@id"]).to eq "https://anotherplatform.ca/portal/profile"
        end
      end
    end
  end
end
