class UpdateWeightCalculators < ActiveRecord::Migration
  def change
    Calculator::Weight.each { |calculator|
      calculator.preferred_unit_from_list = 'kg'
      calculator.preferred_per_unit = calculator.preferred_per_kg
      calculator.preferences.delete(:preferred_per_kg)
      calculator.save
    }
  end
end
