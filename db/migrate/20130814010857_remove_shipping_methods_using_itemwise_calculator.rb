class RemoveShippingMethodsUsingItemwiseCalculator < ActiveRecord::Migration
  class OpenFoodWeb::Calculator::Itemwise < Spree::Calculator; end

  def up
    Spree::ShippingMethod.all.select { |sm| sm.calculator.type == 'OpenFoodWeb::Calculator::Itemwise' }.each do |sm|

      say "Destroying itemwise shipping method with id #{sm.id}"
      sm.destroy
    end
  end

  def down
    Spree::ShippingMethod.create!({name: 'Delivery', zone: Spree::Zone.last, calculator: OpenFoodWeb::Calculator::Itemwise.new}, without_protection: true)
  end
end
