class UpdateWeightCalculators < ActiveRecord::Migration
  def change
    Calculator::Weight.all.each { |calculator|
      calculator.preferred_unit_from_list = 'kg'
      calculator.preferred_per_unit = calculator.preferred_per_kg
      calculator.preferences.delete(:preferred_per_kg)
      Rails.cache.delete(calculator.preference_cache_key("preferred_per_kg"))
      calculator.save
    }
  end
end
