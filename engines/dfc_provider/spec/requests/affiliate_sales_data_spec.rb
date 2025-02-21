# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "AffiliateSalesData", swagger_doc: "dfc.yaml" do
  let(:user) { create(:oidc_user) }

  before { login_as user }

  path "/api/dfc/affiliate_sales_data" do
    parameter name: :startDate, in: :query, type: :string
    parameter name: :endDate, in: :query, type: :string

    get "Show sales data of person's affiliate enterprises" do
      produces "application/json"

      response "200", "successful", feature: :affiliate_sales_data do
        let(:startDate) { Date.yesterday }
        let(:endDate) { Time.zone.today }

        before do
          order = create(:order_with_totals_and_distribution, :completed)
          order.variants.first.product.update!(name: "Tomato")
          ConnectedApps::AffiliateSalesData.new(
            enterprise: order.distributor
          ).connect({})
        end

        context "with date filters" do
          let(:startDate) { Date.tomorrow }
          let(:endDate) { Date.tomorrow }

          run_test! do
            expect(json_response).to include(
              "@id" => "http://test.host/api/dfc/affiliate_sales_data",
              "@type" => "dfc-b:Person",
            )

            expect(json_response["dfc-b:affiliates"]).to eq nil
          end
        end

        context "not filtered" do
          run_test! do
            expect(json_response).to include(
              "@id" => "http://test.host/api/dfc/affiliate_sales_data",
              "@type" => "dfc-b:Person",
            )
            expect(json_response["dfc-b:affiliates"]).to be_present
          end
        end
      end

      response "400", "bad request" do
        let(:startDate) { "yesterday" }
        let(:endDate) { "tomorrow" }

        run_test!
      end
    end
  end
end
