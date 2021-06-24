# frozen_string_literal: true

module EnterpriseFeesHelper
  def angular_name(method)
    "sets_enterprise_fee_set[collection_attributes][{{ $index }}][#{method}]"
  end

  def angular_id(method)
    "sets_enterprise_fee_set_collection_attributes_{{ $index }}_#{method}"
  end

  def enterprise_fee_type_options
    EnterpriseFee::FEE_TYPES.map { |fee_type| [t("#{fee_type}_fee"), fee_type] }
  end
end
