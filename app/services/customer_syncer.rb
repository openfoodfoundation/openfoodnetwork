# frozen_string_literal: true

# Create, find and update customer records.
#
# P.S.: I almost couldn't resist to call this CustomerService.
class CustomerSyncer
  def self.find_and_update_customer(order)
    find_customer(order).tap { |customer| synchronise_email(order, customer) }
  end

  def self.find_customer(order)
    order.user&.customers&.of(order.distributor)&.first ||
      Customer.of(order.distributor).find_by(email: customer_email(order))
  end

  def self.synchronise_email(order, customer)
    email = order.user&.email

    return unless email && customer && email != customer.email

    duplicate = Customer.find_by(email: email, enterprise: order.distributor)

    if duplicate.present?
      Spree::Order.where(customer_id: duplicate.id).update_all(customer_id: customer.id)
      Subscription.where(customer_id: duplicate.id).update_all(customer_id: customer.id)

      duplicate.destroy
    end

    customer.update(email: email)
  end

  def self.create_customer(order)
    Customer.create(
      enterprise: order.distributor,
      email: customer_email(order),
      user: order.user,
      first_name: order.bill_address&.first_name.to_s,
      last_name: order.bill_address&.last_name.to_s,
      bill_address: order.bill_address&.clone,
      ship_address: order.ship_address&.clone
    )
  end

  def self.customer_email(order)
    (order.user&.email || order.email)&.downcase
  end
end
