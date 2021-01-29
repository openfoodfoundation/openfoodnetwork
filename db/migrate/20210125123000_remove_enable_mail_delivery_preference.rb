class RemoveEnableMailDeliveryPreference < ActiveRecord::Migration
  def up
    Spree::Preference.delete_all("key ilike '%enable_mail_delivery%'")
  end

  def down
  end
end
