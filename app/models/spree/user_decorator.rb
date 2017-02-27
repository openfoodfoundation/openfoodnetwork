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
  has_many :credit_cards

  accepts_nested_attributes_for :enterprise_roles, :allow_destroy => true

  accepts_nested_attributes_for :bill_address
  accepts_nested_attributes_for :ship_address

  attr_accessible :enterprise_ids, :enterprise_roles_attributes, :enterprise_limit, :bill_address_attributes, :ship_address_attributes
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
    return nil unless enterprise
    customers.find_by_enterprise_id(enterprise)
  end

  def send_signup_confirmation
    Delayed::Job.enqueue ConfirmSignupJob.new(id)
  end

  def can_own_more_enterprises?
    owned_enterprises(:reload).size < enterprise_limit
  end

  # Returns Enterprise IDs for distributors that the user has shopped at
  def enterprises_ordered_from
    enterprise_ids = orders.where(state: :complete).map(&:distributor_id).uniq
    # Exclude the accounts distributor
    if Spree::Config.accounts_distributor_id
      enterprise_ids = enterprise_ids.keep_if { |a| a != Spree::Config.accounts_distributor_id }
    end
    enterprise_ids
  end

  # Returns orders and their associated payments for all distributors that have been ordered from
  def complete_orders_by_distributor
    Enterprise
      .includes(distributed_orders: { payments: :payment_method })
      .where(enterprises: { id: enterprises_ordered_from },
             spree_orders: { state: 'complete', user_id: id })
      .order('spree_orders.completed_at DESC')
  end

  def orders_by_distributor
    # Remove uncompleted payments as these will not be reflected in order balance
    data_array = complete_orders_by_distributor.to_a
    remove_payments_in_checkout(data_array)
    data_array.sort! { |a, b| b.distributed_orders.length <=> a.distributed_orders.length }
  end

  private

  def limit_owned_enterprises
    if owned_enterprises.size > enterprise_limit
      errors.add(:owned_enterprises, I18n.t(:spree_user_enterprise_limit_error, email: email, enterprise_limit: enterprise_limit))
    end
  end

  def remove_payments_in_checkout(enterprises)
    enterprises.each do |enterprise|
      enterprise.distributed_orders.each do |order|
        order.payments.keep_if { |payment| payment.state != "checkout" }
      end
    end
  end
end
