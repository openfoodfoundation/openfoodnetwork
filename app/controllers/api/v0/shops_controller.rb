# frozen_string_literal: true

module Api
  module V0
    class ShopsController < BaseController
      respond_to :json
      skip_authorization_check only: [:show, :closed_shops]

      def show
        enterprise = Enterprise.find_by(id: params[:id])

        render plain: Api::EnterpriseShopfrontSerializer.new(enterprise).to_json, status: :ok
      end

      def closed_shops
        @active_distributor_ids = []
        @earliest_closing_times = []

        serialized_closed_shops = ActiveModel::ArraySerializer.new(
          ShopsListService.new.closed_shops,
          each_serializer: Api::EnterpriseSerializer,
          data: OpenFoodNetwork::EnterpriseInjectionData.new
        )

        render json: serialized_closed_shops
      end
    end
  end
end
