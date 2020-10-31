# frozen_string_literal: true

module Api
  module Admin
    class InventoryItemSerializer < ActiveModel::Serializer
      attributes :id, :enterprise_id, :variant_id, :visible
    end
  end
end
