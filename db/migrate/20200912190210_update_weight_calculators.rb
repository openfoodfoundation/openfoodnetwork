class UpdateWeightCalculators < ActiveRecord::Migration
  def change
    Spree::Calculator.connection.execute(
      "UPDATE spree_preferences SET key = replace( key, 'per_kg', 'per_unit') WHERE key like '/calculator/weight/per_kg/%'"
    )

    Calculator::Weight.all.each { |calculator|
      calculator.preferred_unit_from_list = 'kg'
      Rails.cache.delete("/calculator/weight/preferred_per_kg/#{calculator.id}")
      calculator.save
    }
  end
end
