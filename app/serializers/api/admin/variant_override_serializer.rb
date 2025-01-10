# frozen_string_literal: true

module Api
  module Admin
    class VariantOverrideSerializer < ActiveModel::Serializer
      attributes :id, :hub_id, :variant_id, :sku, :price, :count_on_hand, :on_demand,
                 :default_stock, :resettable, :tag_list, :tags, :import_date

      def count_on_hand
        return if object.on_demand

        object.count_on_hand
      end

      def tag_list
        object.tag_list.join(",")
      end

      def tags
        object.tag_list.map { |t| { text: t } }
      end
    end
  end
end
