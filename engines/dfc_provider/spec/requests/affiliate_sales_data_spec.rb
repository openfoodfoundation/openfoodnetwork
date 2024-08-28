# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "AffiliateSalesData", swagger_doc: "dfc.yaml", rswag_autodoc: true do
  let(:user) { create(:oidc_user, id: 10_000) }

  before { login_as user }

  path "/api/dfc/affiliate_sales_data" do
    get "Show sales data of person's affiliate enterprises" do
      produces "application/json"

      response "200", "successful" do
        run_test! do
          expect(json_response).to include(
            "@id" => "http://test.host/api/dfc/persons/10000",
          )
        end
      end
    end
  end
end
