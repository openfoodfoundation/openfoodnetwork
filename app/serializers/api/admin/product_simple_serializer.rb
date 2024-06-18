# frozen_string_literal: true

module Api
  module Admin
    class ProductSimpleSerializer < ActiveModel::Serializer
      attributes :id, :name

      has_many :variants, key: :variants, serializer: Api::Admin::VariantSimpleSerializer
    end
  end
end
