# frozen_string_literal: true

module Api
  module Admin
    class UnitsProductSerializer < ActiveModel::Serializer
      attributes :id, :name, :group_buy_unit_size

      def name
        line_item&.full_product_name || object.name
      end

      private

      def line_item
        options[:line_item]
      end
    end
  end
end
