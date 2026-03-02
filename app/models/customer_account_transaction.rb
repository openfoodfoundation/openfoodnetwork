# frozen_string_literal: true

require "spree/localized_number"

class CustomerAccountTransaction < ApplicationRecord
  extend Spree::LocalizedNumber

  localize_number :amount

  belongs_to :customer
  belongs_to :payment_method, -> {
    internal
  }, class_name: "Spree::PaymentMethod", inverse_of: :customer_account_transactions
  belongs_to :payment, class_name: "Spree::Payment", optional: true
  belongs_to :created_by, class_name: "Spree::User", optional: true

  validates :amount, presence: true
  validates :currency, presence: true

  before_create :update_balance

  private

  def readonly?
    !new_record?
  end

  def update_balance
    # Locking the customer to prevent two transactions from behing created at the same time
    # resulting in a potentially wrong balance calculation.
    customer.with_lock(requires_new: true) do
      last_transaction = CustomerAccountTransaction.where(customer: customer).last

      self.balance = if last_transaction.present?
                       last_transaction.balance + amount
                     else
                       amount
                     end
    end
  end
end
