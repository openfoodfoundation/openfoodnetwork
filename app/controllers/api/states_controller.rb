module Api
  class StatesController < Api::BaseController
    respond_to :json

    skip_authorization_check

    def index
      @states = scope.ransack(params[:q]).result.
                  includes(:country).order('name ASC')

      if params[:page] || params[:per_page]
        @states = @states.page(params[:page]).per(params[:per_page])
      end

      render json: @states, each_serializer: Api::StateSerializer, status: :ok
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
  end
end
