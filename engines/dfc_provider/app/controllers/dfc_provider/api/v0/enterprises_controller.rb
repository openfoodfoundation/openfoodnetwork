# frozen_string_literal: true

# Controller used to provide the CatalogItem API for the DFC application
module DfcProvider
  module Api
    module V0
      class EnterprisesController < DfcProvider::Api::V0::BaseController
        before_action :check_enterprise

        def show
          render json: current_enterprise, serializer: DfcProvider::EnterpriseSerializer
        end

        private

        def enterprise_id_param_name
          :id
        end
      end
    end
  end
end
