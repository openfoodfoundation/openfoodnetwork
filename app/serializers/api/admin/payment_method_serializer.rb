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

module Api::Admin::PaymentMethod
  class BaseSerializer < ActiveModel::Serializer
    attributes :id, :name, :type, :tag_list, :tags

    def tag_list
      object.tag_list.join(",")
    end

    def tags
      object.tag_list.map{ |t| { text: t } }
    end
  end

  class StripeSerializer < BaseSerializer
    attributes :preferred_enterprise_id
  end
end
