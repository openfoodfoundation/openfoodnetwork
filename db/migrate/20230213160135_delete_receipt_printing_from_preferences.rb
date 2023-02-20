class DeleteReceiptPrintingFromPreferences < ActiveRecord::Migration[6.1]
  def up
    execute("DELETE FROM spree_preferences WHERE key = '/spree/app_configuration/enable_receipt_printing?'")
  end
end
