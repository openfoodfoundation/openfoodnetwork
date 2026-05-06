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

      organizations = DfcV2Migration.up(enterprises)

      render_container(organizations)
    end

    # The DFC v2 requires containers.
    def render_container(members)
      container = Container.new(organizations_url, members:)

      connector = DataFoodConsortium::Connector::Connector.instance
      render json: connector.export(container, *members), content_type: "application/ld+json"
    end
  end
end
