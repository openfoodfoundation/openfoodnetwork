# frozen_string_literal: true

# Controller used to provide the CatalogItem API for the DFC application
module DfcProvider
  class EnterprisesController < DfcProvider::ApplicationController
    before_action :check_enterprise

    def show
      enterprise = EnterpriseBuilder.enterprise(current_enterprise)
      render json: DfcIo.export(
        enterprise,
        *enterprise.localizations,
        *enterprise.suppliedProducts,
        *enterprise.catalogItems,
      )
    end

    private

    def enterprise_id_param_name
      :id
    end
  end
end
