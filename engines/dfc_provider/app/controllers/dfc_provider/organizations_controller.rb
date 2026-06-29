# frozen_string_literal: true

# A DFC Organization corresponds to our Enterprise.
#
# In DFC v1, this class was called Enterprise but then renamed in v2.
# We are changing the namespace here to align with the DFC v2.
#
# See the EnterprisesController for the backwards-compatible DFC v1 endpoint.
module DfcProvider
  class OrganizationsController < DfcProvider::ApplicationController
    before_action { @profile = "dfc-v2" }

    # List OFN enterprises as DFC Organizations.
    def index
      enterprises = current_user.enterprises.map do |enterprise|
        EnterpriseBuilder.enterprise(enterprise)
      end

      render_dfc(enterprises)
    end

    def show
      enterprise = current_user.enterprises.find(params[:id])
      dfc_enterprise = EnterpriseBuilder.enterprise(enterprise)

      render_dfc(
        dfc_enterprise,
        dfc_enterprise.mainContact,
        *dfc_enterprise.localizations,
        *dfc_enterprise.socialMedias,
        *dfc_enterprise.certifications,
      )
    end
  end
end
