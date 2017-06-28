class AddCheckoutCustomizationToEnterprises < ActiveRecord::Migration
  def change
    add_column :enterprises, :require_phone_number, :boolean, default: :true
    add_column :enterprises, :require_bill_address, :boolean, default: :true
    add_column :enterprises, :hide_comment_box, :boolean, default: :false
    add_column :enterprises, :check_the_only_shipping_option, :boolean, default: :false
    add_column :enterprises, :check_the_only_payment_method, :boolean, default: :false
  end
end
