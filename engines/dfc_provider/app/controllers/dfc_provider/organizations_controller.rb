# frozen_string_literal: true

# A DFC Organization corresponds to our Enterprise.
#
# In DFC v1, this class was called Enterprise but then renamed in v2.
# We are changing the namespace here to align with the DFC v2.
#
# See the EnterprisesController for the backwards-compatible DFC v1 endpoint.
module DfcProvider
  class OrganizationsController < DfcProvider::ApplicationController
    # List OFN enterprises as DFC Organizations.
    def index
      enterprises = current_user.enterprises.map do |enterprise|
        EnterpriseBuilder.enterprise(enterprise)
      end

      render_container(enterprises)
    end

    # The DFC v2 requires containers.
    # TODO: Add DFC Connector class for containers.
    def render_container(members)
      container = {
        "@context" => "https://www.datafoodconsortium.org",
        "@id" => organizations_url,
        "@type" => "ldp:Container",
        "ldp:contains" => members.map(&:semanticId),
      }
      render json: container
    end
  end
end
