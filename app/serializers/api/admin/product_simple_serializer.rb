# frozen_string_literal: true

module Api
  module Admin
    class ProductSimpleSerializer < ActiveModel::Serializer
      attributes :id, :name, :producer_id

      has_many :variants, key: :variants, serializer: Api::Admin::VariantSimpleSerializer

      def producer_id
        object.supplier_id
      end
    end
  end
end
