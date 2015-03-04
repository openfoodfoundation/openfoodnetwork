class EnsureShippingMethodsHaveDistributors < ActiveRecord::Migration
  class Enterprise < ActiveRecord::Base
    scope :is_distributor, where(is_distributor: true)
  end

  def up
    d = Enterprise.is_distributor.first
    sms = Spree::ShippingMethod.where('distributor_id IS NULL')

    if d
      say "Assigning an arbitrary distributor (#{d.name}) to all shipping methods without one (#{sms.count} total)"
      sms.update_all(distributor_id: d)
    else
      say "There are #{sms.count} shipping methods without distributors, but there are no distributors to assign to them"
    end
  end

  def down
  end
end
