class Api::Admin::PaymentMethodSerializer < ActiveModel::Serializer
  delegate :serializable_hash, to: :method_serializer

  def method_serializer
    if object.type == 'Spree::Gateway::StripeConnect'
      Api::Admin::PaymentMethod::StripeSerializer.new(object)
    else
      Api::Admin::PaymentMethod::BaseSerializer.new(object)
    end
  end
end
