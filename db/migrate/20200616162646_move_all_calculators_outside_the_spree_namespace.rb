# frozen_string_literal: true

class MoveAllCalculatorsOutsideTheSpreeNamespace < ActiveRecord::Migration
  def up
    convert_calculator("Spree::Calculator::DefaultTax", "Calculator::DefaultTax")
    convert_calculator("Spree::Calculator::FlatPercentItemTotal",
                       "Calculator::FlatPercentItemTotal")
    convert_calculator("Spree::Calculator::FlatRate", "Calculator::FlatRate")
    convert_calculator("Spree::Calculator::FlexiRate", "Calculator::FlexiRate")
    convert_calculator("Spree::Calculator::PerItem", "Calculator::PerItem")
    convert_calculator("Spree::Calculator::PriceSack", "Calculator::PriceSack")
  end

  def down
    convert_calculator("Calculator::DefaultTax", "Spree::Calculator::DefaultTax")
    convert_calculator("Calculator::FlatPercentItemTotal",
                       "Spree::Calculator::FlatPercentItemTotal")
    convert_calculator("Calculator::FlatRate", "Spree::Calculator::FlatRate")
    convert_calculator("Calculator::FlexiRate", "Spree::Calculator::FlexiRate")
    convert_calculator("Calculator::PerItem", "Spree::Calculator::PerItem")
    convert_calculator("Calculator::PriceSack", "Spree::Calculator::PriceSack")
  end

  private

  def convert_calculator(from, to)
    Spree::Calculator.connection.execute(
      "UPDATE spree_calculators SET type = '" + to + "' WHERE type = '" + from + "'"
    )
  end
end
