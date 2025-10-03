# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Enterprises", swagger_doc: "dfc.yaml" do
  let(:Authorization) { nil }
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) do
    create(
      :distributor_enterprise, :with_logo_image, :with_promo_image,
      id: 10_000, owner: user, abn: "123 456", name: "Fred's Farm",
      description: "This is an awesome enterprise",
      contact_name: "Fred Farmer",
      facebook: "https://facebook.com/user",
      email_address: "hello@example.org",
      phone: "0404 444 000 200",
      website: "https://openfoodnetwork.org",
      address:,
    )
  end
  let(:address) {
    build(
      :address,
      id: 40_000, address1: "42 Doveton Street",
      latitude: -25.345376, longitude: 131.0312006,
    )
  }
  let!(:other_enterprise) do
    create(
      :distributor_enterprise,
      id: 10_001, owner: user, abn: "123 457", name: "Fred's Icecream",
      description: "We use our strawberries to make icecream.",
      address: build(:address, id: 40_001, address1: "42 Doveton Street"),
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
      id: 90_000, name: "Apple", description: "Round",
      variants: [variant],
      primary_taxon: non_local_vegetable
    )
  }
  let(:non_local_vegetable) {
    build(
      :taxon,
      name: "Non Local Vegetable",
      dfc_id: "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/productTypes.rdf#non-local-vegetable"
    )
  }
  let(:variant) {
    build(:base_variant, id: 10_001, unit_value: 1, sku: "APP", supplier: enterprise)
  }

  before { login_as user }

  path "/api/dfc/enterprises" do
    get "List enterprises" do
      produces "application/json"

      response "200", "successful" do
        context "as platform user" do
          include_context "authenticated as platform"

          context "without permissions" do
            run_test! do
              expect(response.body).to eq ""
            end
          end

          context "with access to one enterprise" do
            before do
              DfcPermission.create!(
                user:, enterprise_id: enterprise.id,
                scope: "ReadEnterprise", grantee: "cqcm-dev",
              )
            end

            run_test! do
              expect(response.body).to include "Fred's Farm"
              expect(response.body).not_to include "Fred's Icecream"
            end
          end

          context "with access to two enterprises" do
            before do
              DfcPermission.create!(
                user:, enterprise_id: enterprise.id,
                scope: "ReadEnterprise", grantee: "cqcm-dev",
              )
              DfcPermission.create!(
                user:, enterprise_id: other_enterprise.id,
                scope: "ReadEnterprise", grantee: "cqcm-dev",
              )
            end

            run_test! do
              expect(response.body).to include "Fred's Farm"
              expect(response.body).to include "Fred's Icecream"
            end
          end
        end

        context "as user owning two enterprises" do
          run_test! do
            expect(response.body).to include "Fred's Farm"
            expect(response.body).to include "Fred's Icecream"
          end
        end
      end
    end
  end

  path "/api/dfc/enterprises/{id}" do
    get "Show enterprise" do
      parameter name: :id, in: :path, type: :string
      produces "application/json"

      response "200", "successful" do
        context "as platform user" do
          include_context "authenticated as platform"

          let(:id) { 10_000 }

          before {
            DfcPermission.create!(
              user:, enterprise_id: id,
              scope: "ReadEnterprise", grantee: "cqcm-dev",
            )
          }

          run_test!
        end

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
              "dfc-b:websitePage" => "https://openfoodnetwork.org",
            )
          end
        end
      end

      response "404", "not found" do
        let(:id) { other_enterprise.id }
        let(:other_enterprise) { create(:distributor_enterprise) }

        run_test! do
          expect(response.body).not_to include "Apple"
        end
      end
    end
  end
end
