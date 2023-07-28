# frozen_string_literal: true

module Spree
  class User < ApplicationRecord
    include SetUnusedAddressFields

    self.belongs_to_required_by_default = false

    searchable_attributes :email

    devise :database_authenticatable, :token_authenticatable, :registerable, :recoverable,
           :rememberable, :trackable, :validatable, :omniauthable,
           :encryptable, :confirmable,
           encryptor: 'authlogic_sha512', reconfirmable: true,
           omniauth_providers: [:openid_connect]

    has_many :orders
    belongs_to :ship_address, class_name: 'Spree::Address'
    belongs_to :bill_address, class_name: 'Spree::Address'

    has_and_belongs_to_many :spree_roles,
                            join_table: 'spree_roles_users',
                            class_name: "Spree::Role"

    has_many :spree_orders, class_name: "Spree::Order"

    before_validation :set_login
    after_create :associate_customers, :associate_orders
    before_destroy :check_completed_orders

    roles_table_name = Role.table_name

    scope :admin, lambda { includes(:spree_roles).where("#{roles_table_name}.name" => "admin") }

    has_many :enterprise_roles, dependent: :destroy
    has_many :enterprises, through: :enterprise_roles
    has_many :owned_enterprises, class_name: 'Enterprise',
                                 foreign_key: :owner_id, inverse_of: :owner
    has_many :owned_groups, class_name: 'EnterpriseGroup',
                            foreign_key: :owner_id, inverse_of: :owner
    has_many :customers
    has_many :credit_cards
    has_many :report_rendering_options, class_name: "::ReportRenderingOptions", dependent: :destroy
    has_many :webhook_endpoints, dependent: :destroy

    accepts_nested_attributes_for :enterprise_roles, allow_destroy: true
    accepts_nested_attributes_for :webhook_endpoints

    accepts_nested_attributes_for :bill_address
    accepts_nested_attributes_for :ship_address

    validates :email, 'valid_email_2/email': { mx: true }, if: :email_changed?
    validate :limit_owned_enterprises
    validates :uid, uniqueness: true, if: lambda { uid.present? }

    # Same validation as in the openid_connect gem.
    # This validator is totally outdated but we indirectly depend on it.
    validates :uid, email: true, if: lambda { uid.present? }

    class DestroyWithOrdersError < StandardError; end

    def self.admin_created?
      User.admin.count > 0
    end

    def link_from_omniauth(auth)
      update!(provider: auth.provider, uid: auth.uid)
    end

    # Whether a user has a role or not.
    def has_spree_role?(role_in_question)
      spree_roles.where(name: role_in_question.to_s).any?
    end

    # Checks whether the specified user is a superadmin, with full control of the instance
    def admin?
      has_spree_role?('admin')
    end

    # Send devise-based user emails asyncronously via ActiveJob
    # See: https://github.com/heartcombo/devise/tree/v3.5.10#activejob-integration
    def send_devise_notification(notification, *args)
      devise_mailer.public_send(notification, self, *args).deliver_later
    end

    def regenerate_reset_password_token
      set_reset_password_token
    end

    def generate_api_key
      self.spree_api_key = SecureRandom.hex(24)
    end

    def known_users
      if admin?
        Spree::User.where(nil)
      else
        Spree::User
          .includes(:enterprises)
          .references(:enterprises)
          .where("enterprises.id IN (SELECT enterprise_id FROM enterprise_roles WHERE user_id = ?)",
                 id)
      end
    end

    def build_enterprise_roles
      Enterprise.all.find_each do |enterprise|
        unless enterprise_roles.find_by enterprise_id: enterprise.id
          enterprise_roles.build(enterprise: enterprise)
        end
      end
    end

    def customer_of(enterprise)
      return nil unless enterprise

      customers.find_by(enterprise_id: enterprise)
    end

    # This is a Devise Confirmable callback that runs on email confirmation
    # It sends a welcome email after the user email is confirmed
    def after_confirmation
      return unless confirmed? && unconfirmed_email.nil? && !unconfirmed_email_changed?

      send_signup_confirmation
    end

    def send_signup_confirmation
      Spree::UserMailer.signup_confirmation(self).deliver_later
    end

    def associate_customers
      self.customers = Customer.where(email: email)
    end

    def associate_orders
      Spree::Order.where(customer: customers).find_each do |order|
        order.associate_user!(self)
      end
    end

    def can_own_more_enterprises?
      owned_enterprises.reload.size < enterprise_limit
    end

    def default_card
      # Don't re-fetch associated cards from the DB if they're already eager-loaded
      if credit_cards.loaded?
        credit_cards.to_a.find(&:is_default)
      else
        credit_cards.where(is_default: true).first
      end
    end

    def last_incomplete_spree_order
      spree_orders.incomplete.where(created_by_id: id).order('created_at DESC').first
    end

    def disabled
      disabled_at.present?
    end

    def disabled=(value)
      self.disabled_at = value == '1' ? Time.zone.now : nil
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
