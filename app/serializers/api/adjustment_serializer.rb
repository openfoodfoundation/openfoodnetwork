module Api
  class AdjustmentSerializer < ActiveModel::Serializer
    attributes :id, :amount, :label, :eligible
    attributes :source_type, :source_id
    attributes :adjustable_type, :adjustable_id
    attributes :originator_type, :originator_id
  end
end
