class Api::PaymentSerializer < ActiveModel::Serializer
  attributes :identifier, :amount, :updated_at, :payment_method
  def payment_method
    object.payment_method.name
  end

  def amount
    object.amount.to_money.to_s
  end

  def updated_at
    object.updated_at.to_formatted_s(:long_ordinal)
  end
end
