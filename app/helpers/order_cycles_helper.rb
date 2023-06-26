# frozen_string_literal: true

require 'open_food_network/permissions'

module OrderCyclesHelper
  def current_order_cycle
    @current_order_cycle ||= current_order(false)&.order_cycle
  end

  def permitted_enterprises_for(order_cycle)
    OpenFoodNetwork::OrderCyclePermissions.new(spree_current_user, order_cycle).visible_enterprises
  end

  def permitted_producer_enterprises_for(order_cycle)
    permitted_enterprises_for(order_cycle).is_primary_producer.by_name
  end

  def permitted_producer_enterprise_options_for(order_cycle)
    validated_enterprise_options permitted_producer_enterprises_for(order_cycle)
  end

  def permitted_coordinating_enterprises_for(_order_cycle)
    Enterprise.managed_by(spree_current_user).is_distributor.by_name
  end

  def permitted_coordinating_enterprise_options_for(order_cycle)
    validated_enterprise_options permitted_coordinating_enterprises_for(order_cycle)
  end

  def permitted_hub_enterprises_for(order_cycle)
    permitted_enterprises_for(order_cycle).is_hub.by_name
  end

  def permitted_hub_enterprise_options_for(order_cycle)
    validated_enterprise_options permitted_hub_enterprises_for(order_cycle),
                                 shipping_and_payment_methods: true
  end

  def distributors_with_editable_shipping_and_payment_methods(order_cycle)
    return order_cycle.distributors if Enterprise
      .managed_by(spree_current_user).exists?(order_cycle.coordinator.id)

    order_cycle.distributors.managed_by(spree_current_user)
  end

  def order_cycle_status_class(order_cycle)
    if order_cycle.undated?
      'undated'
    elsif order_cycle.upcoming?
      'upcoming'
    elsif order_cycle.open?
      'open'
    elsif order_cycle.closed?
      'closed'
    end
  end

  def active_order_cycle_for_distributor?(_distributor)
    OrderCycle.active.with_distributor(@distributor).present?
  end

  def simple_index
    @simple_index ||=
      !OpenFoodNetwork::Permissions.new(spree_current_user).can_manage_complex_order_cycles?
  end

  def pickup_time(order_cycle = current_order_cycle)
    order_cycle.exchanges.to_enterprises(current_distributor).outgoing.first.pickup_time
  end

  def can_delete?(order_cycle)
    Spree::Order.where(order_cycle_id: order_cycle).none?
  end

  def viewing_as_coordinator_of?(order_cycle)
    Enterprise.managed_by(spree_current_user).include? order_cycle.coordinator
  end

  private

  def validated_enterprise_options(enterprises, options = {})
    enterprises.map do |e|
      disabled_message = nil
      if options[:shipping_and_payment_methods] &&
         (e.shipping_methods.empty? || e.payment_methods.available.empty?)
        if e.shipping_methods.empty? && e.payment_methods.available.empty?
          disabled_message = I18n.t(:no_shipping_or_payment)
        elsif e.shipping_methods.empty?
          disabled_message = I18n.t(:no_shipping)
        elsif e.payment_methods.available.empty?
          disabled_message = I18n.t(:no_payment)
        end
      end

      if disabled_message
        ["#{e.name} (#{disabled_message})", e.id, { disabled: true }]
      else
        [e.name, e.id]
      end
    end
  end
end
