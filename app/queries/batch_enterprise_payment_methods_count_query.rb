# frozen_string_literal: true

class BatchEnterprisePaymentMethodsCountQuery
  def self.call(enterprise_ids)
    Spree::PaymentMethod.joins(
      "INNER JOIN distributors_payment_methods
       ON distributors_payment_methods.payment_method_id = spree_payment_methods.id"
    ).where(distributors_payment_methods: { distributor_id: enterprise_ids }).
      group("distributor_id").
      count
  end
end
