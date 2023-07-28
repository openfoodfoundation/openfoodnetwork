# frozen_string_literal: true

class DistributorPaymentMethod < ApplicationRecord
  self.table_name = "distributors_payment_methods"

  belongs_to :payment_method, class_name: "Spree::PaymentMethod", touch: true
  belongs_to :distributor, class_name: "Enterprise", touch: true
end
