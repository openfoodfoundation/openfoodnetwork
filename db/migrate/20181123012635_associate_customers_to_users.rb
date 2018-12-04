# When we introduced the Customer model, we didn't associate any existing
# customers with users that have the same email address.
# Later we decided to create that association when users sign up. But we didn't
# update all the existing customers. We do that now for data consistency and to
# solve several bugs.
#
# - https://github.com/openfoodfoundation/openfoodnetwork/pull/2084
# - https://github.com/openfoodfoundation/openfoodnetwork/issues/2841
class AssociateCustomersToUsers < ActiveRecord::Migration
  class Customer < ActiveRecord::Base
  end

  def up
    save_customers
    execute "UPDATE customers
              SET user_id = spree_users.id
              FROM spree_users
              WHERE customers.email = spree_users.email
               AND customers.user_id IS NULL;"
  end

  def down
    customers = backed_up_customers
    Customer.where(id: customers).update_all(user_id: nil)
  end

  def save_customers
    customers = Customer.
      joins("INNER JOIN spree_users ON customers.email = spree_users.email").
      where(user_id: nil).all

    File.write(backup_file, YAML.dump(customers))
  end

  def backed_up_customers
    YAML.load(File.read(backup_file))
  end

  def backup_file
    File.join("log", "customers_without_user_association.log")
  end
end
