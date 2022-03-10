class MigrateCheckoutOnlyToBothBackOfficeAndCheckout < ActiveRecord::Migration[6.1]
  def up
    execute("UPDATE spree_payment_methods SET display_on = NULL WHERE display_on = 'front_end'")
  end
end
