# frozen_string_literal: true

require "spree/localized_number"

class CustomerAccountTransaction < ApplicationRecord
  extend Spree::LocalizedNumber

  localize_number :amount

  belongs_to :customer
  belongs_to :payment_method, class_name: "Spree::PaymentMethod"
  belongs_to :payment, class_name: "Spree::Payment", optional: true

  validates :amount, presence: true
  validates :currency, presence: true
end
