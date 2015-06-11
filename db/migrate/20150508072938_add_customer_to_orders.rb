class AddCustomerToOrders < ActiveRecord::Migration
  def change
    add_column :spree_orders, :customer_id, :integer
    add_index :spree_orders, :customer_id
    add_foreign_key :spree_orders, :customers, column: :customer_id

    Spree::Order.where("spree_orders.email IS NOT NULL AND distributor_id IS NOT NULL AND customer_id IS NULL").each do |order|
      customer = Customer.find_by_email_and_enterprise_id(order.email, order.distributor_id)
      unless customer.present?
        user = Spree::User.find_by_email(order.email)
        customer = Customer.create!(email: order.email, enterprise_id: order.distributor_id, user_id: user.andand.id )
      end
      order.update_attribute(:customer, customer)
    end
  end
end
