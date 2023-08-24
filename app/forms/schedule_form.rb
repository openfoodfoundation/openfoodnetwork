# frozen_string_literal: true

class ScheduleForm
  include ActiveModel::Model

  attr_reader :errors, :flash_success

  def initialize(params, user, schedule = nil)
    @errors = ActiveModel::Errors.new self

    # Not strong
    @params = params
    @current_user = user
    @schedule = schedule
  end

  def save
    editable_order_cycle_ids_for_create

    return false if @params[:order_cycle_ids].blank?

    @schedule.attributes = permitted_resource_params

    if @schedule.save
      @schedule.order_cycle_ids = @params[:order_cycle_ids]
      @schedule.save!

      sync_subscriptions_for_create

    end

    true
  end

  def update(_params)
    editable_order_cycle_ids_for_update

    false unless @schedule.update(permitted_resource_params)

    sync_subscriptions_for_update
  end

  private

  def editable_order_cycle_ids_for_create
    return unless @params[:order_cycle_ids]

    @existing_order_cycle_ids = []
    result = editable_order_cycles(@params[:order_cycle_ids])
    @params[:order_cycle_ids] = result
  end

  def editable_order_cycle_ids_for_update
    return unless @params[:schedule][:order_cycle_ids]

    @existing_order_cycle_ids = @schedule.order_cycle_ids
    result = editable_order_cycles(@params[:schedule][:order_cycle_ids])

    @params[:schedule][:order_cycle_ids] = result
    @schedule.order_cycle_ids = result
  end

  def editable_order_cycles(requested)
    permitted = OrderCycle
      .where(id: @params[:order_cycle_ids] | @existing_order_cycle_ids)
      .merge(OrderCycle.managed_by(@current_user))
      .pluck(:id)
    result = @existing_order_cycle_ids
    result |= (requested & permitted) # add any requested & permitted ids
    # remove any existing and permitted ids that were not specifically requested
    result -= ((result & permitted) - requested)
    result
  end

  def sync_subscriptions_for_create
    return unless @params[:order_cycle_ids]

    sync_subscriptions
  end

  def sync_subscriptions_for_update
    return unless @params[:schedule][:order_cycle_ids] && @schedule.errors.blank?

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
    @params.require(:schedule).permit(:id, :name, order_cycle_ids: [])
  end
end
