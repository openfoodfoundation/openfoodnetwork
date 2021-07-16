# frozen_string_literal: true

# Controller used to provide the CatalogItem API for the DFC application
module DfcProvider
  module Api
    class EnterprisesController < DfcProvider::Api::BaseController
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
