# Initialise enterprise fee when created without one, like this:
# create(:product, :distributors => [...])
# In this case, we don't care what the fee is, but we need one for validations to pass.
ProductDistribution.class_eval do
  before_validation :init_enterprise_fee

  def init_enterprise_fee
    self.enterprise_fee ||= EnterpriseFee.where(enterprise_id: distributor).first || FactoryGirl.create(:enterprise_fee, enterprise_id: distributor)
  end
end
