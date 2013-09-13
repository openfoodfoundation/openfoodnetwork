Spree::PaymentMethod.class_eval do  
  has_and_belongs_to_many :distributors, join_table: 'distributors_payment_methods', :class_name => 'Enterprise', association_foreign_key: 'distributor_id'

  belongs_to :distributor, :class_name => 'Enterprise'

  attr_accessible :distributor_ids

  # -- Scopes
  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      joins(:distributors).
      where('distributors_payment_methods.distributor_id IN (?)', user.enterprises)
    end
  }

  def has_distributor?(distributor)
    self.distributor == distributor
  end
end

# Ensure that all derived classes also allow distributor_id
Spree::Gateway.providers.each do |p|
  p.attr_accessible :distributor_id
end
