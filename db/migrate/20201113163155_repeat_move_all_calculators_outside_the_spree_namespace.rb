# For some unkonwn reason, after removing Spree as a dependency, some spree calculators appeared on live DBs
# Here we repeat the migration
class RepeatMoveAllCalculatorsOutsideTheSpreeNamespace < ActiveRecord::Migration[4.2]
  def up
    convert_calculator("DefaultTax")
    convert_calculator("FlatPercentItemTotal")
    convert_calculator("FlatRate")
    convert_calculator("FlexiRate")
    convert_calculator("PerItem")
    convert_calculator("PriceSack")
  end

  def down
    revert_calculator("DefaultTax")
    revert_calculator("FlatPercentItemTotal")
    revert_calculator("FlatRate")
    revert_calculator("FlexiRate")
    revert_calculator("PerItem")
    revert_calculator("PriceSack")
  end

  private

  def convert_calculator(calculator_base_name)
    update_calculator("Spree::Calculator::" + calculator_base_name,
                      "Calculator::" + calculator_base_name)
  end

  def revert_calculator(calculator_base_name)
    update_calculator("Calculator::" + calculator_base_name,
                      "Spree::Calculator::" + calculator_base_name)
  end

  def update_calculator(from, to)
    Spree::Calculator.connection.execute(
      "UPDATE spree_calculators SET type = '" + to + "' WHERE type = '" + from + "'"
    )
  end
end
