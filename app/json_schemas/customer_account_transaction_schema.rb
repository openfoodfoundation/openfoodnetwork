# frozen_string_literal: true

class CustomerAccountTransactionSchema < JsonApiSchema
  def self.object_name
    "customer_account_transaction"
  end

  def self.attributes
    {
      id: { type: :integer, example: 1 },
      customer_id: { type: :integer, example: 10 },
      amount: { type: :decimal, example: 10.50 },
      currency: { type: :string, example: "AUD" },
      payment_method_id: { type: :integer, example: 100 },
      description: { type: :string, nullable: true, example: "Payment processed by POS" },
      balance: { type: :decimal, example: 10.50 },
    }
  end

  def self.required_attributes
    [:customer_id, :amount]
  end

  def self.writable_attributes
    attributes.except(:id, :balance, :payment_method_id, :currency)
  end

  def self.relationships
    [:customer, :payment_method]
  end
end
