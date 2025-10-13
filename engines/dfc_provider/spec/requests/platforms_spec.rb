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

    get "Show platform scopes" do
      produces "application/json"

      response "200", "successful" do
        let(:enterprise_id) { enterprise.id }
        let(:platform_id) { "cqcm-dev" }

        run_test! do
          expect(json_response["@id"]).to eq "https://api.proxy-dev.cqcm.startinblox.com/profile"
        end
      end
    end

    put "Update authorized scopes of a platform" do
      consumes "application/json"
      produces "application/json"

      parameter name: :platform, in: :body, schema: {
        example: {
          '@context': "https://cdn.startinblox.com/owl/context-bis.jsonld",
          '@id': "http://localhost:3000/api/dfc/enterprises/3/platforms/cqcm-dev",
          'dfc-t:hasAssignedScopes': {
            '@list': [
              {
                '@id': "https://example.com/scopes/ReadEnterprise",
                '@type': "dfc-t:Scope"
              },
              {
                '@id': "https://example.com/scopes/WriteEnterprise",
                '@type': "dfc-t:Scope"
              },
              {
                '@id': "https://example.com/scopes/ReadProducts",
                '@type': "dfc-t:Scope"
              },
              {
                '@id': "https://example.com/scopes/WriteProducts",
                '@type': "dfc-t:Scope"
              },
              {
                '@id': "https://example.com/scopes/ReadOrders",
                '@type': "dfc-t:Scope"
              },
              {
                '@id': "https://example.com/scopes/WriteOrders",
                '@type': "dfc-t:Scope"
              }
            ],
            '@type': "rdf:List"
          }
        }
      }

      response "200", "successful" do
        let(:enterprise_id) { enterprise.id }
        let(:platform_id) { "cqcm-dev" }
        let(:platform) do |example|
          example.metadata[:operation][:parameters].first[:schema][:example]
        end

        before do
          stub_request(:post, "https://kc.cqcm.startinblox.com/realms/startinblox/protocol/openid-connect/token")
            .and_return(body: { access_token: "testtoken" }.to_json)
          stub_request(:post, "https://api.proxy-dev.cqcm.startinblox.com/djangoldp-dfc/webhook/")
        end

        run_test! do
          expect(json_response["@id"]).to eq "https://api.proxy-dev.cqcm.startinblox.com/profile"
        end
      end
    end
  end
end
