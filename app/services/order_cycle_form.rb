require 'open_food_network/permissions'
require 'open_food_network/proxy_order_syncer'
require 'open_food_network/order_cycle_form_applicator'

class OrderCycleForm
  def initialize(order_cycle, params, user)
    @order_cycle = order_cycle
    @params = params
    @user = user
    @permissions = OpenFoodNetwork::Permissions.new(user)
  end

  def save
    build_schedule_ids
    order_cycle.assign_attributes(params[:order_cycle])
    return false unless order_cycle.valid?
    order_cycle.transaction do
      order_cycle.save!
      apply_exchange_changes
      sync_subscriptions
      true
    end
  rescue ActiveRecord::RecordInvalid
    false
  end

  private

  attr_accessor :order_cycle, :params, :user, :permissions

  def apply_exchange_changes
    return if exchanges_unchanged?
    OpenFoodNetwork::OrderCycleFormApplicator.new(order_cycle, user).go!
  end

  def exchanges_unchanged?
    [:incoming_exchanges, :outgoing_exchanges].all? do |direction|
      params[:order_cycle][direction].nil?
    end
  end

  def schedule_ids?
    params[:order_cycle][:schedule_ids].present?
  end

  def build_schedule_ids
    return unless schedule_ids?
    result = existing_schedule_ids
    result |= (requested_schedule_ids & permitted_schedule_ids) # Add permitted and requested
    result -= ((result & permitted_schedule_ids) - requested_schedule_ids) # Remove permitted but not requested
    params[:order_cycle][:schedule_ids] = result
  end

  def sync_subscriptions
    return unless schedule_ids?
    return unless schedule_sync_required?
    OpenFoodNetwork::ProxyOrderSyncer.new(subscriptions_to_sync).sync!
  end

  def schedule_sync_required?
    removed_schedule_ids.any? || new_schedule_ids.any?
  end

  def subscriptions_to_sync
    Subscription.where(schedule_id: removed_schedule_ids + new_schedule_ids)
  end

  def requested_schedule_ids
    params[:order_cycle][:schedule_ids].map(&:to_i)
  end

  def permitted_schedule_ids
    Schedule.where(id: requested_schedule_ids | existing_schedule_ids)
      .merge(permissions.editable_schedules).pluck(:id)
  end

  def existing_schedule_ids
    @existing_schedule_ids ||= order_cycle.persisted? ? order_cycle.schedule_ids : []
  end

  def removed_schedule_ids
    existing_schedule_ids - order_cycle.schedule_ids
  end

  def new_schedule_ids
    @order_cycle.schedule_ids - existing_schedule_ids
  end
end
