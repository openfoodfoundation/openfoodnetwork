class UpdateWeightCalculators < ActiveRecord::Migration[4.2]
  def change
    Spree::Calculator.connection.execute(
      "UPDATE spree_preferences SET key = replace( key, 'per_kg', 'per_unit') WHERE key ilike '/calculator/weight/per_kg/%'"
    )

    Calculator::Weight.all.each { |calculator|
      calculator.preferred_unit_from_list = 'kg'
      Rails.cache.delete("/calculator/weight/per_kg/#{calculator.id}")
      calculator.save
    }
  end
end
