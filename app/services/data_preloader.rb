# frozen_string_literal: true

class DataPreloader
  def self.preload_enterprise_data(enterprises)
    enterprise_ids = enterprises.map(&:id)

    return if enterprise_ids.empty?

    enterprise_fees_counts = BatchEnterpriseEnterpriseFeesCountQuery.call(enterprise_ids)
    payment_methods_counts = BatchEnterprisePaymentMethodsCountQuery.call(enterprise_ids)
    producer_properties_counts = BatchEnterpriseProducerPropertiesCountQuery.call(enterprise_ids)
    shipping_methods_counts = BatchEnterpriseShippingMethodsCountQuery.call(enterprise_ids)

    enterprises.each do |enterprise|
      enterprise.preloaded_data = OpenStruct.new(
        {
          enterprise_fees_count: enterprise_fees_counts[enterprise.id] || 0,
          payment_methods_count: payment_methods_counts[enterprise.id] || 0,
          producer_properties_count: producer_properties_counts[enterprise.id] || 0,
          shipping_methods_count: shipping_methods_counts[enterprise.id] || 0
        }
      )
    end
  end
end
