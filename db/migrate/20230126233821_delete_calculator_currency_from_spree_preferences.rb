class DeleteCalculatorCurrencyFromSpreePreferences < ActiveRecord::Migration[6.1]
  class SpreePreference < ActiveRecord::Base
  end

  def up
    # Delete all currency preferences for calculators, they are no longer used.
    rows = SpreePreference.where("key like '/calculator%/currency/%'").delete_all
    puts "#{rows} rows deleted."
  end

  def down
    # Sorry, the data was deleted!
    raise ActiveRecord::IrreversibleMigration
  end
end
