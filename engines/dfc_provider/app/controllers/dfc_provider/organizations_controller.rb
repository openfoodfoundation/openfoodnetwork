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

    def show
      enterprise = current_user.enterprises.find(params[:id])
      dfc_enterprise = EnterpriseBuilder.enterprise(enterprise)
      organization = DfcV2Migration.up([dfc_enterprise]).first

      render_v2(
        organization,
        organization.mainContact,
        *organization.localizations,
        *organization.socialMedias,
      )
    end

    private

    # The DFC v2 requires containers.
    def render_container(members)
      container = Container.new(organizations_url, members:)

      render_v2(container, *members)
    end
  end
end
