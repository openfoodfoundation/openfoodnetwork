# frozen_string_literal: true

class PaymentsRequiringAction
  def initialize(user)
    @user = user
  end

  attr_reader :user

  def query
    Spree::Payment.joins(order: [:user]).where.not(cvv_response_message: nil).
      where("spree_users.id = ?", user.id)
  end
end
