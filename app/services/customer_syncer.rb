# frozen_string_literal: true

# Create, find and update customer records.
#
# P.S.: I almost couldn't resist to call this CustomerService.
class CustomerSyncer
  attr_reader :customer, :distributor, :user

  def initialize(order)
    @customer = order.customer
    @distributor = order.distributor
    @user = order.user
  end

  # Update the customer record if the user changed their email address.
  def synchronise_customer_email
    if user && customer && user.email != customer.email
      duplicate = Customer.find_by(email: user.email, enterprise: distributor)

      if duplicate.present?
        Spree::Order.where(customer_id: duplicate.id).update_all(customer_id: customer.id)
        Subscription.where(customer_id: duplicate.id).update_all(customer_id: customer.id)

        duplicate.destroy
      end

      customer.update(email: user.email)
    end
  end
end
