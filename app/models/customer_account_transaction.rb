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

  validates :amount, presence: true
  validates :currency, presence: true

  before_create :update_balance

  private

  def readonly?
    !new_record?
  end

  def update_balance
    # We are creating the initial transaction, no need to calculate the balance
    return if initial_transaction?

    first_transaction = CustomerAccountTransaction.where(customer: customer).first
    if first_transaction.nil?
      first_transaction = create_initial_transaction
    end

    # The first transaction will always exists, so we lock it to ensure only one transaction
    # is processed at the time to ensure the correct balance calculation.
    first_transaction.with_lock("FOR UPDATE") do
      last_transaction = CustomerAccountTransaction.where(customer: customer).last
      self.balance = last_transaction.balance + amount
    end
  end

  # Creates the first transaction with a 0 amount
  def create_initial_transaction
    api_payment_method = customer.enterprise.payment_methods.internal.find_by!(
      name: Rails.application.config.api_payment_method[:name]
    )
    CustomerAccountTransaction.create!(
      customer: customer,
      amount: 0.00,
      currency: CurrentConfig.get(:currency),
      description: I18n.t("customer_account_transaction.account_creation"),
      payment_method: api_payment_method
    )
  end

  def initial_transaction?
    description == I18n.t("customer_account_transaction.account_creation") && amount == 0.00
  end
end
