Spree::PaymentMethod.class_eval do  
  belongs_to :distributor, :class_name => 'Enterprise'

  attr_accessible :distributor_id

  # -- Scopes
  scope :in_distributor, lambda { |distributor| where(:distributor_id => distributor) }

  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      where('distributor_id IN (?)', user.enterprises.map {|enterprise| enterprise.id })
    end
  }
end