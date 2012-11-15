module EnterpriseFeesHelper
  def enterprise_fee_options
    EnterpriseFee::FEE_TYPES.map { |f| [f.capitalize, f] }
  end
end
