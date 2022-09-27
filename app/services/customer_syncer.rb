# frozen_string_literal: true

# Create, find and update customer records.
#
# P.S.: I almost couldn't resist to call this CustomerService.
class CustomerSyncer
  def self.create_customer(order)
    Customer.create(
      enterprise: order.distributor,
      email: (order.user&.email || order.email)&.downcase,
      user: order.user,
      first_name: order.bill_address&.first_name.to_s,
      last_name: order.bill_address&.last_name.to_s,
      bill_address: order.bill_address&.clone,
      ship_address: order.ship_address&.clone
    )
  end

  attr_reader :customer, :distributor, :user

  def initialize(order)
    @customer = order.customer
    @distributor = order.distributor
    @user = order.user
  end

  # Update the customer record if the user changed their email address.
  def synchronise_customer_email
    return unless user && customer && user.email != customer.email

    duplicate = Customer.find_by(email: user.email, enterprise: distributor)

    if duplicate.present?
      Spree::Order.where(customer_id: duplicate.id).update_all(customer_id: customer.id)
      Subscription.where(customer_id: duplicate.id).update_all(customer_id: customer.id)

      duplicate.destroy
    end

    customer.update(email: user.email)
  end
end
