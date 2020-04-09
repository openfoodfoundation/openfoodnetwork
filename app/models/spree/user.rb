module Spree
  class User < ActiveRecord::Base
    devise :database_authenticatable, :token_authenticatable, :registerable, :recoverable,
           :rememberable, :trackable, :validatable, :encryptable, encryptor: 'authlogic_sha512'

    has_many :orders
    belongs_to :ship_address, foreign_key: 'ship_address_id', class_name: 'Spree::Address'
    belongs_to :bill_address, foreign_key: 'bill_address_id', class_name: 'Spree::Address'

    before_validation :set_login
    before_destroy :check_completed_orders

    # Setup accessible (or protected) attributes for your model
    attr_accessible :email, :password, :password_confirmation,
                    :remember_me, :persistence_token, :login

    users_table_name = User.table_name
    roles_table_name = Role.table_name

    scope :admin, lambda { includes(:spree_roles).where("#{roles_table_name}.name" => "admin") }
    scope :registered, -> { where("#{users_table_name}.email NOT LIKE ?", "%@example.net") }

    has_many :enterprise_roles, dependent: :destroy
    has_many :enterprises, through: :enterprise_roles
    has_many :owned_enterprises, class_name: 'Enterprise',
                                 foreign_key: :owner_id, inverse_of: :owner
    has_many :owned_groups, class_name: 'EnterpriseGroup',
                            foreign_key: :owner_id, inverse_of: :owner
    has_many :customers
    has_many :credit_cards

    accepts_nested_attributes_for :enterprise_roles, allow_destroy: true

    accepts_nested_attributes_for :bill_address
    accepts_nested_attributes_for :ship_address

    attr_accessible :enterprise_ids, :enterprise_roles_attributes, :enterprise_limit,
                    :locale, :bill_address_attributes, :ship_address_attributes
    after_create :associate_customers

    validate :limit_owned_enterprises

    # We use the same options as Spree and add :confirmable
    devise :confirmable, reconfirmable: true
    # TODO: Later versions of devise have a dedicated after_confirmation callback, so use that
    after_update :welcome_after_confirm, if: lambda {
      confirmation_token_changed? && confirmation_token.nil?
    }

    class DestroyWithOrdersError < StandardError; end

    # Creates an anonymous user. An anonymous user is basically an auto-generated +User+ account
    # that is created for the customer behind the scenes and it's transparent to the customer.
    # All +Orders+ must have a +User+ so this is necessary when adding to the "cart" (an order)
    # and before the customer has a chance to provide an email or to register.
    def self.anonymous!
      token = User.generate_token(:persistence_token)
      User.create(email: "#{token}@example.net",
                  password: token, password_confirmation: token, persistence_token: token)
    end

    def self.admin_created?
      User.admin.count > 0
    end

    def admin?
      has_spree_role?('admin')
    end

    def anonymous?
      email =~ /@example.net$/ ? true : false
    end

    def send_reset_password_instructions
      generate_reset_password_token!
      UserMailer.reset_password_instructions(id).deliver
    end
    # handle_asynchronously will define send_reset_password_instructions_with_delay.
    # If handle_asynchronously is called twice, we get an infinite job loop.
    handle_asynchronously :send_reset_password_instructions unless method_defined? :send_reset_password_instructions_with_delay

    def known_users
      if admin?
        Spree::User.scoped
      else
        Spree::User
          .includes(:enterprises)
          .where("enterprises.id IN (SELECT enterprise_id FROM enterprise_roles WHERE user_id = ?)",
                 id)
      end
    end

    def build_enterprise_roles
      Enterprise.all.find_each do |enterprise|
        unless enterprise_roles.find_by_enterprise_id enterprise.id
          enterprise_roles.build(enterprise: enterprise)
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
      return unless confirmed? && unconfirmed_email.nil? && !unconfirmed_email_changed?

      send_signup_confirmation
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
      # Don't re-fetch associated cards from the DB if they're already eager-loaded
      if credit_cards.loaded?
        credit_cards.to_a.find(&:is_default)
      else
        credit_cards.where(is_default: true).first
      end
    end

    # Checks whether the specified user is a superadmin, with full control of the
    # instance
    #
    # @return [Boolean]
    def superadmin?
      has_spree_role?('admin')
    end

    def generate_spree_api_key!
      self.spree_api_key = SecureRandom.hex(24)
      save!
    end

    def clear_spree_api_key!
      self.spree_api_key = nil
      save!
    end

    protected

    def password_required?
      !persisted? || password.present? || password_confirmation.present?
    end

    private

    def check_completed_orders
      raise DestroyWithOrdersError if orders.complete.present?
    end

    def set_login
      # for now force login to be same as email, eventually we will make this configurable, etc.
      self.login ||= email if email
    end

    # Generate a friendly string randomically to be used as token.
    def self.friendly_token
      SecureRandom.base64(15).tr('+/=', '-_ ').strip.delete("\n")
    end

    # Generate a token by looping and ensuring does not already exist.
    def self.generate_token(column)
      loop do
        token = friendly_token
        break token unless find(:first, conditions: { column => token })
      end
    end

    def limit_owned_enterprises
      return unless owned_enterprises.size > enterprise_limit

      errors.add(:owned_enterprises, I18n.t(:spree_user_enterprise_limit_error,
                                            email: email,
                                            enterprise_limit: enterprise_limit))
    end

    def remove_payments_in_checkout(enterprises)
      enterprises.each do |enterprise|
        enterprise.distributed_orders.each do |order|
          order.payments.keep_if { |payment| payment.state != "checkout" }
        end
      end
    end
  end
end
