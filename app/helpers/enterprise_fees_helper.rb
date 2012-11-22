module EnterpriseFeesHelper
  def enterprise_fee_type_options
    EnterpriseFee::FEE_TYPES.map { |f| [f.capitalize, f] }
  end
end
