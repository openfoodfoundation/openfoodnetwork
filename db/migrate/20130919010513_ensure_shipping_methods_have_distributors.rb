class EnsureShippingMethodsHaveDistributors < ActiveRecord::Migration
  def up
    d = Enterprise.is_distributor.first
    sms = Spree::ShippingMethod.where('distributor_id IS NULL')
    say "Assigning an arbitrary distributor (#{d.name}) to all shipping methods without one (#{sms.count} total)"

    sms.update_all(distributor_id: d)
  end

  def down
  end
end
