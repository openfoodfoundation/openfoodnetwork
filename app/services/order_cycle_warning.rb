# frozen_string_literal: true

class OrderCycleWarning
  def initialize(current_user)
    @current_user = current_user
  end

  def call
    distributors = active_distributors_not_ready_for_checkout

    return if distributors.empty?

    active_distributors_not_ready_for_checkout_message(distributors)
  end

  private

  attr_reader :current_user

  def active_distributors_not_ready_for_checkout
    ocs = OrderCycle.managed_by(current_user).active
    distributors = ocs.includes(:distributors).map(&:distributors).flatten.uniq
    Enterprise.where(id: distributors.map(&:id)).not_ready_for_checkout
  end

  def active_distributors_not_ready_for_checkout_message(distributors)
    distributor_names = distributors.map(&:name).join ', '

    if distributors.count > 1
      I18n.t(:active_distributors_not_ready_for_checkout_message_plural,
             distributor_names: distributor_names)
    else
      I18n.t(:active_distributors_not_ready_for_checkout_message_singular,
             distributor_names: distributor_names)
    end
  end
end
