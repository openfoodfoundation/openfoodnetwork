# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Webids", swagger_doc: "dfc.yaml" do
  path("/api/dfc/webid") do
    get("Show platform WebID") do
      produces("application/ld+json")

      response("200", "successful") do
        subject {
          JSON.parse(response.body, object_class: ActiveSupport::HashWithIndifferentAccess)
        }

        run_test! do
          graph = subject["@graph"]
          expect(graph[0]["@id"]).to(eq("http://test.host/api/dfc/webid"))
          expect(graph[0]["@type"]).to(eq("foaf:PersonalProfileDocument"))
          expect(graph[1]["foaf:name"]).to(eq("Open Food Network"))
        end
      end
    end
  end
end
