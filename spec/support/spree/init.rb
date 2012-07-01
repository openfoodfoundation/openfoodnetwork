# Initialise shipping method when created without one, like this:
# create(:product, :distributors => [...])
# In this case, we don't care what the shipping method is, but we need one for validations to pass.
Spree::ProductDistribution.class_eval do
  before_validation :init_shipping_method

  def init_shipping_method
    self.shipping_method ||= Spree::ShippingMethod.first || FactoryGirl.create(:shipping_method)
  end
end
