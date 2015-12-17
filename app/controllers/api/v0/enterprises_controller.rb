class Api::V0::EnterprisesController < Api::V0::BaseController

  def index
    @scope = collection.ransack(params[:q]).result
    render_collection @scope, each_serializer: Api::V0::EnterpriseSerializer, root: 'enterprises'
  end

  def show
    @object = collection.find(params[:id])
    render json: @object, serializer: Api::V0::EnterpriseSerializer
  end

  private

  # @see Admin::EnterprisesController#collection
  def collection
    OpenFoodNetwork::Permissions.new(current_api_user).
      visible_enterprises.
      includes(:address => [:country, :state]).
      order('is_primary_producer ASC, name')
  end
end
