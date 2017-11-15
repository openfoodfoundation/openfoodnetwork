require 'open_food_network/permissions'
require 'open_food_network/proxy_order_syncer'

module Admin
  class SchedulesController < ResourceController
    before_filter :check_editable_order_cycle_ids, only: [:create, :update]
    create.after :sync_standing_orders
    update.after :sync_standing_orders

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
      @existing_order_cycle_ids = @schedule.persisted? ? @schedule.order_cycle_ids : []
      permitted = OrderCycle.where(id: params[:schedule][:order_cycle_ids] | @existing_order_cycle_ids).merge(OrderCycle.managed_by(spree_current_user)).pluck(:id)
      result = @existing_order_cycle_ids
      result |= (requested & permitted) # add any requested & permitted ids
      result -= ((result & permitted) - requested) # remove any existing and permitted ids that were not specifically requested
      params[:schedule][:order_cycle_ids] = result
      @object.order_cycle_ids = result
    end

    def permissions
      return @permissions unless @permission.nil?
      @permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
    end

    def sync_standing_orders
      return unless params[:schedule][:order_cycle_ids]
      removed_ids = @existing_order_cycle_ids - @schedule.order_cycle_ids
      new_ids = @schedule.order_cycle_ids - @existing_order_cycle_ids
      if removed_ids.any? || new_ids.any?
        standing_orders = StandingOrder.where(schedule_id: @schedule)
        syncer = OpenFoodNetwork::ProxyOrderSyncer.new(standing_orders)
        syncer.sync!
      end
    end
  end
end
