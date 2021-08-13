# frozen_string_literal: true

class BatchEnterpriseEnterpriseFeesCountQuery
  def self.call(enterprise_ids)
    EnterpriseFee.where(enterprise_id: enterprise_ids).group(:enterprise_id).count
  end
end
