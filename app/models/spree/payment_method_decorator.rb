Spree::PaymentMethod.class_eval do
  has_and_belongs_to_many :distributors, join_table: 'distributors_payment_methods', :class_name => 'Enterprise', association_foreign_key: 'distributor_id'

  attr_accessible :distributor_ids

  # -- Scopes
  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      joins(:distributors).
      where('distributors_payment_methods.distributor_id IN (?)', user.enterprises).
      select('DISTINCT spree_payment_methods.*')
    end
  }

  scope :by_distributor, lambda {
    joins(:distributors).
    order('enterprises.name, spree_payment_methods.name').
    select('enterprises.*, spree_payment_methods.*')
  }

  def has_distributor?(distributor)
    self.distributors.include?(distributor)
  end
end

# Ensure that all derived classes also allow distributor_ids
Spree::Gateway.providers.each do |p|
  p.attr_accessible :distributor_ids
end
