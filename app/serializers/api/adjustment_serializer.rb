module Api
  class AdjustmentSerializer < ActiveModel::Serializer
    attributes :id, :amount, :label, :eligible,
               :source_type, :source_id,
               :adjustable_type, :adjustable_id
  end
end
