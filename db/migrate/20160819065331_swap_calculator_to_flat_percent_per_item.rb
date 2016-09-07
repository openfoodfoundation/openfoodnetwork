class SwapCalculatorToFlatPercentPerItem < ActiveRecord::Migration
  class Spree::Calculator < ActiveRecord::Base
  end

  def up
    Spree::Calculator.where(calculable_type: "EnterpriseFee", type: 'Spree::Calculator::FlatPercentItemTotal').each do |c|
      swap_calculator_type c, 'Calculator::FlatPercentPerItem'
    end
  end

  def down
    Spree::Calculator.where(calculable_type: "EnterpriseFee", type: 'Spree::Calculator::FlatPercentPerItem').each do |c|
      swap_calculator_type c, 'Calculator::FlatPercentItemTotal'
    end
  end


  private

  def swap_calculator_type(calculator, to_class)
    value = calculator.preferred_flat_percent

    calculator.type = to_class
    calculator.save

    calculator = Spree::Calculator.find calculator.id
    calculator.preferred_flat_percent = value
  end
end
