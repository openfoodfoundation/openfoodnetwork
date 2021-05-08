module Api
  class AdjustmentSerializer < ActiveModel::Serializer
    attributes :id, :amount, :label, :eligible,
               :adjustable_type, :adjustable_id,
               :originator_type, :originator_id
  end
end
