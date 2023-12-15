# frozen_string_literal: true

require_relative "../swagger_helper"

describe "Enterprises", type: :request, swagger_doc: "dfc.yaml", rswag_autodoc: true do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) do
    create(
      :distributor_enterprise, :with_logo_image,
      id: 10_000, owner: user, abn: "123 456", name: "Fred's Farm",
      description: "This is an awesome enterprise",
      contact_name: "Fred Farmer",
      facebook: "https://facebook.com/user",
      email_address: "hello@example.org",
      phone: "0404 444 000 200",
      website: "https://openfoodnetwork.org",
      address: build(:address, id: 40_000, address1: "42 Doveton Street"),
    )
  end
  let!(:enterprise_group) do
    create(
      :enterprise_group,
      id: 60_000, owner: user, name: "Local Farmers",
      enterprises: [enterprise],
    )
  end
  let!(:product) {
    create(
      :product_with_image,
      id: 90_000, supplier: enterprise, name: "Apple", description: "Round",
      variants: [variant],
      primary_taxon: build(:taxon, name: "Non local vegetable", dfc_name: "non local vegetable"),
    )
  }
  let(:variant) { build(:base_variant, id: 10_001, unit_value: 1, sku: "APP") }

  before { login_as user }

  path "/api/dfc/enterprises/{id}" do
    get "Show enterprise" do
      parameter name: :id, in: :path, type: :string
      produces "application/json"

      response "200", "successful" do
        context "without enterprise id" do
          let(:id) { "default" }

          run_test! do
            expect(response.body).to include("Apple")
            expect(response.body).to include("APP")
            expect(response.body).to include("offers/10001")
          end
        end

        context "given an enterprise id" do
          let(:id) { enterprise.id }

          run_test! do
            expect(response.body).to include "Fred's Farm"
            expect(response.body).to include "This is an awesome enterprise"
            expect(response.body).to include "123 456"
            expect(response.body).to include "Apple"
            expect(response.body).to include "42 Doveton Street"

            expect(json_response["@graph"][0]).to include(
              "dfc-b:affiliates" => "http://test.host/api/dfc/enterprise_groups/60000",
            )

            # Insert static value to keep documentation deterministic:
            response.body.gsub!(
              %r{active_storage/[0-9A-Za-z/=-]*/logo-white.png},
              "active_storage/url/logo-white.png",
            ).gsub!(
              %r{active_storage/[0-9A-Za-z/=-]*/logo.png},
              "active_storage/url/logo.png",
            )
          end
        end
      end

      response "404", "not found" do
        let(:id) { other_enterprise.id }
        let(:other_enterprise) { create(:distributor_enterprise) }

        run_test! do
          expect(response.body).to_not include "Apple"
        end
      end
    end
  end
end
