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
      add_certifications(enterprise, organization)

      render_v2(
        organization,
        organization.mainContact,
        *organization.localizations,
        *organization.socialMedias,
        *organization.certifications,
      )
    end

    private

    # We don't have certification data but we do have some self-declared
    # properties. Examples of properties are:
    #
    # - Free Range
    # - Organic - Certified
    # - Vegetarian
    #
    # This logic should live in a builder class but the current builders still
    # work on DFC v1. This method will do for now until we have upgraded our
    # builders.
    def add_certifications(enterprise, organization)
      enterprise.properties.each do |property|
        organization.certifications << DataFoodConsortium::Connector::Certification.new(
          "#certification-#{property.id}",
          name: property.name,
        )
      end
    end

    # The DFC v2 requires containers.
    def render_container(members)
      container = Container.new(organizations_url, members:)

      render_v2(container, *members)
    end
  end
end
