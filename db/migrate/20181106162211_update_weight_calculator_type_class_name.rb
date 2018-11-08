class UpdateWeightCalculatorTypeClassName < ActiveRecord::Migration
  def up
    Spree::Calculator.connection.execute("UPDATE spree_calculators SET type = 'Calculator::Weight' WHERE type = 'OpenFoodNetwork::Calculator::Weight'")
  end

  def down
    Spree::Calculator.connection.execute("UPDATE spree_calculators SET type = 'OpenFoodNetwork::Calculator::Weight' WHERE type = 'Calculator::Weight'")
  end
end
