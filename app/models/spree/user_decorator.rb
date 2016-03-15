Spree.user_class.class_eval do
  # handle_asynchronously will define send_reset_password_instructions_with_delay.
  # If handle_asynchronously is called twice, we get an infinite job loop.
  handle_asynchronously :send_reset_password_instructions unless method_defined? :send_reset_password_instructions_with_delay

  has_many :enterprise_roles, :dependent => :destroy
  has_many :enterprises, through: :enterprise_roles
  has_many :owned_enterprises, class_name: 'Enterprise', foreign_key: :owner_id, inverse_of: :owner
  has_many :owned_groups, class_name: 'EnterpriseGroup', foreign_key: :owner_id, inverse_of: :owner
  has_many :account_invoices
  has_many :billable_periods, foreign_key: :owner_id, inverse_of: :owner
  has_one :cart
  has_many :customers

  accepts_nested_attributes_for :enterprise_roles, :allow_destroy => true

  attr_accessible :enterprise_ids, :enterprise_roles_attributes, :enterprise_limit
  after_create :send_signup_confirmation

  validate :limit_owned_enterprises

  def known_users
    if admin?
      Spree::User.scoped
    else
      Spree::User
      .includes(:enterprises)
      .where("enterprises.id IN (SELECT enterprise_id FROM enterprise_roles WHERE user_id = ?)", id)
    end
  end

  def build_enterprise_roles
    Enterprise.all.each do |enterprise|
      unless self.enterprise_roles.find_by_enterprise_id enterprise.id
        self.enterprise_roles.build(:enterprise => enterprise)
      end
    end
  end

  def customer_of(enterprise)
    customers.of(enterprise).first
  end

  def send_signup_confirmation
    Delayed::Job.enqueue ConfirmSignupJob.new(id)
  end

  def can_own_more_enterprises?
    owned_enterprises(:reload).size < enterprise_limit
  end

  # Returns Enterprise IDs for distributors that the user has shopped at
  def enterprises_ordered_from
    self.orders.where(state: :complete).map(&:distributor_id).uniq
  end

  def orders_by_distributor
    distributors_with_orders.to_a.sort! do |a, b|
      b.distributed_orders.length <=> a.distributed_orders.length
    end
  end

  private

  def limit_owned_enterprises
    if owned_enterprises.size > enterprise_limit
      errors.add(:owned_enterprises, "^#{email} is not permitted to own any more enterprises (limit is #{enterprise_limit}).")
    end
  end

  def distributors_with_orders
    Enterprise
    .select("DISTINCT enterprises.*")
    .joins("LEFT OUTER JOIN spree_orders ON spree_orders.distributor_id = enterprises.id")
    .joins("LEFT OUTER JOIN spree_payments ON spree_payments.order_id = spree_orders.id
           AND spree_payments.state = 'completed'")
    .joins("LEFT OUTER JOIN spree_payment_methods ON spree_payment_methods.id = spree_payments.payment_method_id")
    .where(enterprises: { id: enterprises_ordered_from },
           spree_orders: { state: 'complete', user_id: id })
  end
end
