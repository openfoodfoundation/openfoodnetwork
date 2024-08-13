# frozen_string_literal: true

module Api
  module Admin
    class UnitsProductSerializer < ActiveModel::Serializer
      attributes :id, :name, :group_buy_unit_size
    end
  end
end
