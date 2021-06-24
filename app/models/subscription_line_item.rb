# frozen_string_literal: true

class SubscriptionLineItem < ApplicationRecord
  belongs_to :subscription, inverse_of: :subscription_line_items
  belongs_to :variant, -> { with_deleted }, class_name: 'Spree::Variant'

  validates :subscription, presence: true
  validates :variant, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true }

  default_scope { order('id ASC') }

  def total_estimate
    (price_estimate || 0) * (quantity || 0)
  end

  # Used to calculators to estimate fees
  alias_method :amount, :total_estimate

  # Used to calculators to estimate fees
  def price
    price_estimate
  end
end
