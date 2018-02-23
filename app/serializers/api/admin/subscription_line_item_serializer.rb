module Api
  module Admin
    class SubscriptionLineItemSerializer < ActiveModel::Serializer
      attributes :id, :variant_id, :quantity, :description, :price_estimate

      def description
        "#{object.variant.product.name} - #{object.variant.full_name}"
      end

      def price_estimate
        object.price_estimate.andand.to_f || "?"
      end
    end
  end
end
