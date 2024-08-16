# frozen_string_literal: true

require 'open_food_network/permissions'

module Admin
  class SchedulesController < Admin::ResourceController
    include PaperTrailLogging

    before_action :adapt_params, only: [:update]
    before_action :check_dependent_subscriptions

    after_action :sync_subscriptions_for_update, only: :update

    respond_to :json

    OVERRIDE_RESPONSE = { json: {
      success: lambda {
                 render_as_json @schedule,
                                editable_schedule_ids: permissions.editable_schedules.pluck(:id)
               },
      failure: lambda {
                 render json: { errors: @schedule.errors.full_messages },
                        status: :unprocessable_entity
               }
    } }.freeze

    respond_override create: OVERRIDE_RESPONSE
    respond_override update: OVERRIDE_RESPONSE

    def index
      respond_to do |format|
        format.json do
          render_as_json(
            @collection,
            ams_prefix: params[:ams_prefix],
            editable_schedule_ids: permissions.editable_schedules.pluck(:id)
          )
        end
      end
    end

    def create
      @schedule_form = ScheduleForm.new(params, spree_current_user, @schedule)

      if @schedule_form.save
        flash[:success] = flash_message_for(@schedule, :successfully_created)
        @existing_order_cycle_ids = []
        sync_subscriptions_for_create
      end

      respond_with(@schedule)
    end

    def update
      @existing_order_cycle_ids = @schedule.order_cycle_ids
      @object = ScheduleForm.new(params, spree_current_user, @schedule)
      super
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

    # In this controller, params like params[:name] are moved into
    #   params[:schedule] becoming params[:schedule][:name].
    # For some reason in rails 4, this is not happening for params[:order_cycle_ids]
    #   We do it manually in this filter
    def adapt_params
      params[:schedule] = {} if params[:schedule].blank?
      params[:schedule][:order_cycle_ids] = params[:order_cycle_ids]
    end

    def check_dependent_subscriptions
      return if Subscription.where(schedule_id: @schedule).empty?

      render json: { errors: [t('admin.schedules.destroy.associated_subscriptions_error')] },
             status: :conflict
    end

    def permissions
      return @permissions unless @permission.nil?

      @permissions = OpenFoodNetwork::Permissions.new(spree_current_user)
    end

    def sync_subscriptions_for_create
      return unless params[:order_cycle_ids]

      sync_subscriptions
    end

    def sync_subscriptions_for_update
      return unless params[:schedule][:order_cycle_ids] && @schedule.errors.blank?

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
      params.require(:schedule).permit(:id, :name, order_cycle_ids: [])
    end
  end
end
