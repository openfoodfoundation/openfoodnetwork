# frozen_string_literal: true

class PaymentsRequiringAction
  def initialize(user)
    @user = user
  end

  def query
    Spree::Payment.joins(:order).where("spree_orders.user_id = ?", user.id).
      requires_authorization
  end

  private

  attr_reader :user
end
