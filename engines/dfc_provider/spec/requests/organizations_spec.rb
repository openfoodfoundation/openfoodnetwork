# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Organizations", swagger_doc: "dfc.yaml" do
  let(:Authorization) { auth_header_token_for(owner) }
  let(:owner) { create(:oidc_user) }
  let(:enterprise) do
    create(
      :distributor_enterprise, :with_logo_image, :with_promo_image,
      id: 10_000, owner: owner, abn: "123 456", name: "Fred's Farm",
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

  path "/api/dfc/organizations" do
    get "List organizations" do
      produces "application/ld+json"

      response "200", "successful" do
        context "as user owning an enterprise" do
          before { enterprise }

          run_test! do
            expect(response.body).to include "test.host/api/dfc/organizations"

            # DFC v2 requires containers. We can't just list objects in a graph.
            expect(response.body).to include '"@type":"ldp:Container"'

            # The container contains the enterprise.
            #
            # I also kept the semantic id the same, still referring to
            # enterprise. Technically, it doesn't matter. But since DFC v2
            # includes breaking changes, I want to rename this as well and add
            # a `show` action to the OrganizationsController.
            #
            # This means that the ids of resources will change. If another
            # platform like Discover Regenerative has the old ids stored and
            # wants to upgrade to DFC v2 then they need to update their
            # database to change all the stored ids of enterprises.
            expect(response.body).to include "host/api/dfc/enterprises/10000"
            expect(response.body).to include "Fred's Farm"
          end
        end
      end
    end
  end
end
