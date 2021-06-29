# frozen_string_literal: true

module Api
  module V0
    class StatesController < Api::V0::BaseController
      respond_to :json

      skip_authorization_check

      def index
        render json: states, each_serializer: Api::StateSerializer, status: :ok
      end

      def show
        @state = scope.find(params[:id])
        render json: @state, serializer: Api::StateSerializer, status: :ok
      end

      private

      def scope
        if params[:country_id]
          @country = Spree::Country.find(params[:country_id])
          @country.states
        else
          Spree::State.all
        end
      end

      def states
        states = scope.ransack(params[:q]).result.
          includes(:country).order('name ASC')

        if pagination?
          _pagy, states = pagy(states)
        end

        states
      end

      def pagination?
        params[:page] || params[:per_page]
      end
    end
  end
end
