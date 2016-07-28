require 'open_food_network/permissions'

module Admin
  class SchedulesController < ResourceController
    before_filter :check_editable_order_cycle_ids, only: [:create, :update]

    respond_to :json

    respond_override create: { json: {
      success: lambda { render_as_json @schedule, editable_schedule_ids: permissions.editable_schedules.pluck(:id) },
      failure: lambda { render json: { errors: @schedule.errors.full_messages }, status: :unprocessable_entity }
    } }
    respond_override update: { json: {
      success: lambda { render_as_json @schedule, editable_schedule_ids: permissions.editable_schedules.pluck(:id) },
      failure: lambda { render json: { errors: @schedule.errors.full_messages }, status: :unprocessable_entity }
    } }


    def index
      respond_to do |format|
        format.json do
          render_as_json @collection, ams_prefix: params[:ams_prefix], editable_schedule_ids: permissions.editable_schedules.pluck(:id)
        end
      end
    end

    private
    def collection
      return Schedule.where("1=0") unless json_request?
      permissions.visible_schedules
    end

    def collection_actions
      [:index]
    end

    def check_editable_order_cycle_ids
      return unless params[:schedule][:order_cycle_ids]
      requested = params[:schedule][:order_cycle_ids]
      existing = @schedule.persisted? ? @schedule.order_cycle_ids : []
      permitted = OrderCycle.where(id: params[:schedule][:order_cycle_ids] | existing).merge(OrderCycle.managed_by(spree_current_user)).pluck(:id)
      result = existing
      result |= (requested & permitted) # add any requested & permitted ids
      result -= ((result & permitted) - requested) # remove any existing and permitted ids that were not specifically requested
      params[:schedule][:order_cycle_ids] = result
      @object.order_cycle_ids = result
    end

    def permissions
      return @permissions unless @permission.nil?
      @permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
    end
  end
end
