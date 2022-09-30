# frozen_string_literal: false

# Resets an order by verifying it's state and fixing any issues
class OrderCartReset
  def initialize(order, distributor_id)
    @order = order
    @distributor ||= Enterprise.is_distributor.find_by(permalink: distributor_id) ||
                     Enterprise.is_distributor.find(distributor_id)
  end

  def reset_distributor
    if order.distributor && order.distributor != distributor
      order.empty!
      order.set_order_cycle! nil
    end
    order.distributor = distributor
  end

  def reset_other!(current_user, current_customer)
    reset_user_and_customer(current_user)
    reset_order_cycle(current_customer)
    order.save!
  end

  private

  attr_reader :order, :distributor, :current_user

  def reset_user_and_customer(current_user)
    return unless current_user

    order.associate_user!(current_user) if order.user.blank? || order.email.blank?
  end

  def reset_order_cycle(current_customer)
    listed_order_cycles = Shop::OrderCyclesList.active_for(distributor, current_customer)

    if order_cycle_not_listed?(order.order_cycle, listed_order_cycles)
      order.order_cycle = nil
      order.empty!
    end

    select_default_order_cycle(order, listed_order_cycles)
  end

  def order_cycle_not_listed?(order_cycle, listed_order_cycles)
    order_cycle.present? && !listed_order_cycles.include?(order_cycle)
  end

  # If no OC is selected and there is only one in the list of OCs, selects it
  def select_default_order_cycle(order, listed_order_cycles)
    return unless order.order_cycle.blank? && listed_order_cycles.size == 1

    order.order_cycle = listed_order_cycles.first
  end
end
