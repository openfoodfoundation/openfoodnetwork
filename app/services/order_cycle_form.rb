# frozen_string_literal: true

require 'open_food_network/permissions'
require 'open_food_network/order_cycle_form_applicator'
require 'order_management/subscriptions/proxy_order_syncer'

class OrderCycleForm
  def initialize(order_cycle, order_cycle_params, user)
    @order_cycle = order_cycle
    @order_cycle_params = order_cycle_params
    @specified_params = order_cycle_params.keys
    @user = user
    @permissions = OpenFoodNetwork::Permissions.new(user)
    @schedule_ids = order_cycle_params.delete(:schedule_ids)
    @selected_distributor_payment_method_ids = order_cycle_params.delete(
      :selected_distributor_payment_method_ids
    )
    @selected_distributor_shipping_method_ids = order_cycle_params.delete(
      :selected_distributor_shipping_method_ids
    )
  end

  def save
    schedule_ids = build_schedule_ids
    order_cycle.assign_attributes(order_cycle_params)
    return false unless order_cycle.valid?

    order_cycle.transaction do
      order_cycle.save!
      order_cycle.schedule_ids = schedule_ids if parameter_specified?(:schedule_ids)
      order_cycle.save!
      apply_exchange_changes
      if can_update_selected_payment_or_shipping_methods?
        attach_selected_distributor_payment_methods
        attach_selected_distributor_shipping_methods
      end
      sync_subscriptions
      true
    end
  rescue ActiveRecord::RecordInvalid => e
    add_exception_to_order_cycle_errors(e)
    false
  end

  private

  attr_accessor :order_cycle, :order_cycle_params, :user, :permissions

  def add_exception_to_order_cycle_errors(exception)
    error = exception.message.split(":").last.strip
    order_cycle.errors.add(:base, error) if order_cycle.errors.to_a.exclude?(error)
  end

  def apply_exchange_changes
    return if exchanges_unchanged?

    OpenFoodNetwork::OrderCycleFormApplicator.new(order_cycle, user).go!

    # reload so outgoing exchanges are up-to-date for shipping/payment method validations
    order_cycle.reload
  end

  def attach_selected_distributor_payment_methods
    return if @selected_distributor_payment_method_ids.nil?

    if distributor_only?
      payment_method_ids = order_cycle.selected_distributor_payment_method_ids
      payment_method_ids -= user_distributor_payment_method_ids
      payment_method_ids += user_only_selected_distributor_payment_method_ids
      order_cycle.selected_distributor_payment_method_ids = payment_method_ids
    else
      order_cycle.selected_distributor_payment_method_ids = selected_distributor_payment_method_ids
    end
    order_cycle.save!
  end

  def attach_selected_distributor_shipping_methods
    return if @selected_distributor_shipping_method_ids.nil?

    if distributor_only?
      # A distributor can only update methods associated with their own
      # enterprise, so we load all previously selected methods, and replace
      # only the distributor's methods with their selection (not touching other
      # distributor's methods).
      shipping_method_ids = order_cycle.selected_distributor_shipping_method_ids
      shipping_method_ids -= user_distributor_shipping_method_ids
      shipping_method_ids += user_only_selected_distributor_shipping_method_ids
      order_cycle.selected_distributor_shipping_method_ids = shipping_method_ids
    else
      order_cycle.selected_distributor_shipping_method_ids = selected_distributor_shipping_method_ids
    end

    order_cycle.save!
  end

  def attachable_distributor_payment_method_ids
    @attachable_distributor_payment_method_ids ||= order_cycle.attachable_distributor_payment_methods.map(&:id)
  end

  def attachable_distributor_shipping_method_ids
    @attachable_distributor_shipping_method_ids ||= order_cycle.attachable_distributor_shipping_methods.map(&:id)
  end

  def exchanges_unchanged?
    [:incoming_exchanges, :outgoing_exchanges].all? do |direction|
      order_cycle_params[direction].nil?
    end
  end

  def selected_distributor_payment_method_ids
    @selected_distributor_payment_method_ids = (
      attachable_distributor_payment_method_ids &
      @selected_distributor_payment_method_ids.reject(&:blank?).map(&:to_i)
    )

    if attachable_distributor_payment_method_ids.sort == @selected_distributor_payment_method_ids.sort
      @selected_distributor_payment_method_ids = []
    end

    @selected_distributor_payment_method_ids
  end

  def user_only_selected_distributor_payment_method_ids
    user_distributor_payment_method_ids.intersection(selected_distributor_payment_method_ids)
  end

  def selected_distributor_shipping_method_ids
    @selected_distributor_shipping_method_ids = (
      attachable_distributor_shipping_method_ids &
      @selected_distributor_shipping_method_ids.reject(&:blank?).map(&:to_i)
    )

    if attachable_distributor_shipping_method_ids.sort == @selected_distributor_shipping_method_ids.sort
      @selected_distributor_shipping_method_ids = []
    end

    @selected_distributor_shipping_method_ids
  end

  def user_only_selected_distributor_shipping_method_ids
    user_distributor_shipping_method_ids.intersection(selected_distributor_shipping_method_ids)
  end

  def build_schedule_ids
    return unless parameter_specified?(:schedule_ids)

    result = existing_schedule_ids
    result |= (requested_schedule_ids & permitted_schedule_ids) # Add permitted and requested
    result -= ((result & permitted_schedule_ids) - requested_schedule_ids) # Remove permitted but not requested
    result
  end

  def sync_subscriptions
    return unless parameter_specified?(:schedule_ids)
    return unless schedule_sync_required?

    OrderManagement::Subscriptions::ProxyOrderSyncer.new(subscriptions_to_sync).sync!
  end

  def schedule_sync_required?
    removed_schedule_ids.any? || new_schedule_ids.any?
  end

  def subscriptions_to_sync
    Subscription.where(schedule_id: removed_schedule_ids + new_schedule_ids)
  end

  def requested_schedule_ids
    @schedule_ids.map(&:to_i)
  end

  def parameter_specified?(key)
    @specified_params.map(&:to_s).include?(key.to_s)
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

  def can_update_selected_payment_or_shipping_methods?
    @user.admin? || coordinator? || distributor?
  end

  def coordinator?
    @user.enterprises.include?(@order_cycle.coordinator)
  end

  def distributor?
    !user_distributors_ids.empty?
  end

  def distributor_only?
    distributor? && !@user.admin? && !coordinator?
  end

  def user_distributors_ids
    @user_distributors_ids ||= @user.enterprises.pluck(:id)
      .intersection(@order_cycle.distributors.pluck(:id))
  end

  def user_distributor_payment_method_ids
    @user_distributor_payment_method_ids ||=
      DistributorPaymentMethod.where(distributor_id: user_distributors_ids)
        .pluck(:id)
  end

  def user_distributor_shipping_method_ids
    @user_distributor_shipping_method_ids ||=
      DistributorShippingMethod.where(distributor_id: user_distributors_ids)
        .pluck(:id)
  end
end
