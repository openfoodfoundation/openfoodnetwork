# Initialise shipping method when created without one, like this:
# create(:product, :distributors => [...])
# In this case, we don't care what the shipping method is, but we need one for validations to pass.
ProductDistribution.class_eval do
  before_validation :init_shipping_method

  def init_shipping_method
    self.shipping_method ||= Spree::ShippingMethod.first || FactoryGirl.create(:shipping_method)
  end
end

Spree::Product.class_eval do
  before_validation :init_shipping_method

  def init_shipping_method
    FactoryGirl.create(:shipping_method) if Spree::ShippingMethod.where("name != 'Delivery'").empty?
  end

end

# Create a default shipping method, required when creating orders
Spree::Order.class_eval do
  before_create :init_shipping_method

  def init_shipping_method
    FactoryGirl.create(:itemwise_shipping_method) unless Spree::ShippingMethod.all.any? { |sm| sm.calculator.is_a? OpenFoodWeb::Calculator::Itemwise }
  end
end
