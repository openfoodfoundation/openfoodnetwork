# frozen_string_literal: true

class PaymentsRequiringAction
  def initialize(user)
    @user = user
  end

  def query
    Spree::Payment.joins(order: [:user]).where.not(cvv_response_message: nil).
      where("spree_users.id = ?", user.id)
  end

  private

  attr_reader :user
end
