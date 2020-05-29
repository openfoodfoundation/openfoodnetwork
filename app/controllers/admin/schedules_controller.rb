require 'open_food_network/permissions'
require 'order_management/subscriptions/proxy_order_syncer'

module Admin
  class SchedulesController < ResourceController
    before_filter :adapt_params, only: [:update]
    before_filter :check_editable_order_cycle_ids_create, only: [:create]
    before_filter :check_editable_order_cycle_ids_update, only: [:update]
    before_filter :check_dependent_subscriptions, only: [:destroy]
    update.after :sync_subscriptions_update

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

    def create
      if params[:order_cycle_ids].blank?
        return respond_with(@schedule)
      end

      @schedule.attributes = permitted_resource_params

      if @schedule.save
        @schedule.order_cycle_ids = params[:order_cycle_ids]
        @schedule.save!

        sync_subscriptions_create

        flash[:success] = flash_message_for(@schedule, :successfully_created)
        respond_with(@schedule)
      else
        respond_with(@schedule)
      end
    end

    private

    def collection
      return Schedule.where("1=0") unless json_request?

      if params[:enterprise_id]
        filter_schedules_by_enterprise_id(permissions.visible_schedules, params[:enterprise_id])
      else
        permissions.visible_schedules
      end
    end

    # Filter schedules by OCs with a given coordinator id
    def filter_schedules_by_enterprise_id(schedules, enterprise_id)
      schedules.joins(:order_cycles).where(order_cycles: { coordinator_id: enterprise_id.to_i })
    end

    def collection_actions
      [:index]
    end

    # In this controller, params like params[:name] are moved into params[:schedule] becoming params[:schedule][:name]
    # For some reason in rails 4, this is not happening for params[:order_cycle_ids]
    #   We do it manually in this filter
    def adapt_params
      params[:schedule] = {} if params[:schedule].blank?
      params[:schedule][:order_cycle_ids] = params[:order_cycle_ids]
    end

    def check_editable_order_cycle_ids_create
      return unless params[:order_cycle_ids]

      requested = params[:order_cycle_ids]
      @existing_order_cycle_ids = []

      result = editable_order_cycles(requested)

      params[:order_cycle_ids] = result
    end

    def check_editable_order_cycle_ids_update
      return unless params[:schedule][:order_cycle_ids]

      requested = params[:schedule][:order_cycle_ids]
      @existing_order_cycle_ids = @schedule.order_cycle_ids

      result = editable_order_cycles(requested)

      params[:schedule][:order_cycle_ids] = result
      @schedule.order_cycle_ids = result
    end

    def editable_order_cycles(requested)
      permitted = OrderCycle
        .where(id: params[:order_cycle_ids] | @existing_order_cycle_ids)
        .merge(OrderCycle.managed_by(spree_current_user))
        .pluck(:id)
      result = @existing_order_cycle_ids
      result |= (requested & permitted) # add any requested & permitted ids
      result -= ((result & permitted) - requested) # remove any existing and permitted ids that were not specifically requested
      result
    end

    def check_dependent_subscriptions
      return if Subscription.where(schedule_id: @schedule).empty?

      render json: { errors: [t('admin.schedules.destroy.associated_subscriptions_error')] }, status: :conflict
    end

    def permissions
      return @permissions unless @permission.nil?

      @permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
    end

    def sync_subscriptions_update
      return unless params[:schedule][:order_cycle_ids]

      sync_subscriptions
    end

    def sync_subscriptions_create
      return unless params[:order_cycle_ids]

      sync_subscriptions
    end

    def sync_subscriptions
      removed_ids = @existing_order_cycle_ids - @schedule.order_cycle_ids
      new_ids = @schedule.order_cycle_ids - @existing_order_cycle_ids
      return unless removed_ids.any? || new_ids.any?

      subscriptions = Subscription.where(schedule_id: @schedule)
      syncer = OrderManagement::Subscriptions::ProxyOrderSyncer.new(subscriptions)
      syncer.sync!
    end

    def permitted_resource_params
      params.require(:schedule).permit(:id, :name)
    end
  end
end
