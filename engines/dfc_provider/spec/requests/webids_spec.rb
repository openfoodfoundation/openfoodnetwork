# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Webids", swagger_doc: "dfc.yaml" do
  subject {
    JSON.parse(response.body, object_class: ActiveSupport::HashWithIndifferentAccess)
  }

  path("/api/dfc/webid") do
    get("Show platform WebID") do
      produces("application/ld+json")

      response("200", "successful") do
        run_test! do
          graph = subject["@graph"]
          expect(graph[0]["@id"]).to(eq("http://test.host/api/dfc/webid"))
          expect(graph[0]["@type"]).to(eq("foaf:PersonalProfileDocument"))
          expect(graph[1]["foaf:name"]).to(eq("Open Food Network"))
        end
      end
    end
  end

  path("/api/dfc/persons/{id}/webid") do
    let(:user) { create(:oidc_user, id: 9_000) }

    get("Show user WebID") do
      parameter(name: :id, in: :path, type: :string)

      produces("application/ld+json")

      response("200", "successful") do
        let(:id) { user.id }

        run_test! do
          graph = subject["@graph"]
          expect(graph[0]["@id"]).to(eq("http://test.host/api/dfc/persons/9000/webid"))
          expect(graph[0]["@type"]).to(eq("foaf:PersonalProfileDocument"))
          expect(graph[1]["pim:preferencesFile"]).to(eq("TBC"))
        end
      end
    end
  end
end
