require 'open_food_network/permissions'
require 'open_food_network/proxy_order_syncer'

class OrderCycleForm
  def initialize(order_cycle, params, user)
    @order_cycle = order_cycle
    @params = params
    @permissions = OpenFoodNetwork::Permissions.new(user)
  end

  def save
    check_editable_schedule_ids
    order_cycle.assign_attributes(params[:order_cycle])
    return false unless order_cycle.valid?
    order_cycle.transaction do
      order_cycle.save!
      sync_subscriptions
      true
    end
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  attr_accessor :order_cycle, :params, :permissions

  def check_editable_schedule_ids
    return unless params[:order_cycle][:schedule_ids]
    requested = params[:order_cycle][:schedule_ids].map(&:to_i)
    @existing_schedule_ids = @order_cycle.persisted? ? @order_cycle.schedule_ids : []
    permitted = Schedule.where(id: requested | @existing_schedule_ids).merge(permissions.editable_schedules).pluck(:id)
    result = @existing_schedule_ids
    result |= (requested & permitted) # add any requested & permitted ids
    result -= ((result & permitted) - requested) # remove any existing and permitted ids that were not specifically requested
    params[:order_cycle][:schedule_ids] = result
  end

  def sync_subscriptions
    return unless params[:order_cycle][:schedule_ids]
    removed_ids = @existing_schedule_ids - @order_cycle.schedule_ids
    new_ids = @order_cycle.schedule_ids - @existing_schedule_ids
    if removed_ids.any? || new_ids.any?
      schedules = Schedule.where(id: removed_ids + new_ids)
      subscriptions = Subscription.where(schedule_id: schedules)
      syncer = OpenFoodNetwork::ProxyOrderSyncer.new(subscriptions)
      syncer.sync!
    end
  end
end
