# frozen_string_literal: true

class BatchEnterpriseProducerPropertiesCountQuery
  def self.call(enterprise_ids)
    ProducerProperty.where(producer_id: enterprise_ids).group(:producer_id).unscope(:order).count
  end
end
