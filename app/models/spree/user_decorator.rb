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

  attr_accessible :enterprise_ids, :enterprise_roles_attributes, :enterprise_limit, :locale, :bill_address_attributes, :ship_address_attributes
  after_create :associate_customers

  validate :limit_owned_enterprises

  # We use the same options as Spree and add :confirmable
  devise :confirmable, reconfirmable: true
  handle_asynchronously :send_confirmation_instructions
  handle_asynchronously :send_on_create_confirmation_instructions
  # TODO: Later versions of devise have a dedicated after_confirmation callback, so use that
  after_update :welcome_after_confirm, if: lambda { confirmation_token_changed? && confirmation_token.nil? }

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

  def welcome_after_confirm
    # Send welcome email if we are confirming an user's email
    # Note: this callback only runs on email confirmation
    if confirmed? && unconfirmed_email.nil? && !unconfirmed_email_changed?
      send_signup_confirmation
    end
  end

  def send_signup_confirmation
    Delayed::Job.enqueue ConfirmSignupJob.new(id)
  end

  def associate_customers
    self.customers = Customer.where(email: email)
  end

  def can_own_more_enterprises?
    owned_enterprises(:reload).size < enterprise_limit
  end

  def default_card
    credit_cards.where(is_default: true).first
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
