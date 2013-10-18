class RemoveShippingMethodsUsingItemwiseCalculator < ActiveRecord::Migration
  class OpenFoodNetwork::Calculator::Itemwise < Spree::Calculator; end

  def up
    Spree::ShippingMethod.all.select { |sm| sm.calculator.type == 'OpenFoodNetwork::Calculator::Itemwise' }.each do |sm|

      say "Destroying itemwise shipping method with id #{sm.id}"
      sm.destroy
    end
  end

  def down
    Spree::ShippingMethod.create!({name: 'Delivery', zone: Spree::Zone.last, calculator: OpenFoodNetwork::Calculator::Itemwise.new}, without_protection: true)
  end
end
