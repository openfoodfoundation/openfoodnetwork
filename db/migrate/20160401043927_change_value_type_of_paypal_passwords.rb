class ChangeValueTypeOfPaypalPasswords < ActiveRecord::Migration
  def up
    Spree::Preference
      .where("key like ?", "spree/gateway/pay_pal_express/password/%")
      .where(value_type: "string")
      .update_all(value_type: "password")
  end

  def down
    Spree::Preference
      .where("key like ?", "spree/gateway/pay_pal_express/password/%")
      .where(value_type: "password")
      .update_all(value_type: "string")
  end
end
