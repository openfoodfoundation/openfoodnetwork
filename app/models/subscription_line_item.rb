# frozen_string_literal: true

class SubscriptionLineItem < ApplicationRecord
  belongs_to :subscription, inverse_of: :subscription_line_items
  belongs_to :variant, -> { with_deleted }, class_name: 'Spree::Variant', inverse_of: false

  validates :quantity, presence: true, numericality: { only_integer: true }

  default_scope { order('id ASC') }
  scope :nil_price_estimate, -> { where(price_estimate: nil) }

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
