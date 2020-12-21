# frozen_string_literal: true

module Api
  module Admin
    module Calculator
      class FlatPercentItemTotalSerializer < ActiveModel::Serializer
        attributes :id, :preferred_flat_percent

        def preferred_flat_percent
          object.preferred_flat_percent.to_i
        end
      end
    end
  end
end
