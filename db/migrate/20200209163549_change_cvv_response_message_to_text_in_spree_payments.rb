class ChangeCvvResponseMessageToTextInSpreePayments < ActiveRecord::Migration[4.2]
  def up
    change_column :spree_payments, :cvv_response_message, :text
  end

  def down
    change_column :spree_payments, :cvv_response_message, :string
  end
end
