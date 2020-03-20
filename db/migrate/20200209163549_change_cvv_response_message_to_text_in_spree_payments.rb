class ChangeCvvResponseMessageToTextInSpreePayments < ActiveRecord::Migration
  def up
    change_column :spree_payments, :cvv_response_message, :text
  end

  def down
    change_column :spree_payments, :cvv_response_message, :string
  end
end
