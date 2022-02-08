# frozen_string_literal: true

module Api
  module Admin
    class PaymentMethodSerializer < ActiveModel::Serializer
      delegate :serializable_hash, to: :method_serializer

      def method_serializer
        if object.type == 'Spree::Gateway::StripeSCA'
          Api::Admin::PaymentMethod::StripeSerializer.new(object, options)
        else
          Api::Admin::PaymentMethod::BaseSerializer.new(object, options)
        end
      end
    end
  end
end
