# frozen_string_literal: true

class BatchEnterpriseShippingMethodsCountQuery
  def self.call(enterprise_ids)
    Spree::ShippingMethod.joins(
      "INNER JOIN distributors_shipping_methods
      ON distributors_shipping_methods.shipping_method_id = spree_shipping_methods.id"
    ).where(distributors_shipping_methods: { distributor_id: enterprise_ids }).
      group("distributor_id").
      count
  end
end
