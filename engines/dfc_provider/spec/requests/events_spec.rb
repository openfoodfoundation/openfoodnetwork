# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Events", swagger_doc: "dfc.yaml" do
  include_context "authenticated as platform" do
    let(:access_token) {
      file_fixture("fdc_access_token.jwt").read
    }
  end

  path "/api/dfc/events" do
    post "Create Event" do
      consumes "application/json"
      produces "application/json"

      parameter name: :event, in: :body, schema: {
        example: {
          eventType: "refresh",
          enterpriseUrlid: "https://api.beta.litefarm.org/dfc/enterprises/",
          scope: "ReadEnterprise",
        }
      }

      response "400", "bad request" do
        describe "with missing request body" do
          around do |example|
            # Rswag expects all required parameters to be supplied with `let`
            # but we want to send a request without the request body parameter.
            parameters = example.metadata[:operation][:parameters]
            example.metadata[:operation][:parameters] = []
            example.run
            example.metadata[:operation][:parameters] = parameters
          end

          run_test!
        end

        describe "with empty request body" do
          let(:event) { nil }
          run_test!
        end

        describe "with missing parameter" do
          let(:event) { { eventType: "refresh" } }
          run_test!
        end
      end

      response "401", "unauthorised" do
        describe "as normal user" do
          let(:Authorization) { nil }
          let(:event) { { eventType: "refresh" } }

          before { login_as create(:oidc_user) }

          run_test!
        end

        describe "as other platform" do
          let(:access_token) {
            file_fixture("startinblox_access_token.jwt").read
          }
          let(:event) { { eventType: "refresh" } }

          before { login_as create(:oidc_user) }

          run_test!
        end
      end

      response "200", "success" do
        let(:event) do |example|
          example.metadata[:operation][:parameters].first[:schema][:example]
        end

        before do
          stub_request(:post, %r{openid-connect/token$})
          stub_request(:get, "https://api.beta.litefarm.org/dfc/enterprises/")
            .to_return(body: "[]")
        end

        run_test! do
          expect(json_response["success"]).to eq true
        end
      end
    end
  end
end
