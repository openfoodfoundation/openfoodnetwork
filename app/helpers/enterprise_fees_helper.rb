module EnterpriseFeesHelper
  def angular_name(method)
    "enterprise_fee_set[collection_attributes][{{ $index }}][#{method}]"
  end

  def angular_id(method)
    "enterprise_fee_set_collection_attributes_{{ $index }}_#{method}"
  end

  def enterprise_fee_type_options
    EnterpriseFee::FEE_TYPES.map { |f| [f.capitalize, f] }
  end
end
