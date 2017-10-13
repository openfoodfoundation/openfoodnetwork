module Api
  module Admin
    module Reports
      class OrdersAndFulfillmentSerializer < ActiveModel::Serializer
        has_many :line_items, serializer: Api::Admin::Reports::LineItemSerializer
        has_many :orders, serializer: Api::Admin::Reports::OrderSerializer
        has_many :variants, serializer: Api::Admin::Reports::VariantSerializer
        has_many :products, serializer: Api::Admin::Reports::ProductSerializer
      end
    end
  end
end
