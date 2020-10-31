# frozen_string_literal: true

module Api
  module Admin
    class TaxCategorySerializer < ActiveModel::Serializer
      attributes :id, :name
    end
  end
end
