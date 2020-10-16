# frozen_string_literal: true

module Api
  module Admin
    class CalculatorSerializer < ActiveModel::Serializer
      attributes :name, :description

      delegate :name, to: :object

      delegate :description, to: :object
    end
  end
end
