# frozen_string_literal: true

# A customer record is created the first time a person orders from a shop.
#
# It's a relationship between a user and an enterprise but for guest orders it
# can also be between an email address and an enterprise.
#
# The main purpose is tagging of customers to access private shops, receive
# discounts et cetera. A customer record is also needed for subscriptions.
class Customer < ApplicationRecord
  include SetUnusedAddressFields

  acts_as_taggable

  searchable_attributes :first_name, :last_name, :email, :code

  belongs_to :enterprise
  belongs_to :user, class_name: "Spree::User", optional: true
  has_many :orders, class_name: "Spree::Order"
  before_validation :downcase_email
  before_validation :empty_code
  before_create :associate_user
  before_destroy :update_orders_and_delete_canceled_subscriptions

  belongs_to :bill_address, class_name: "Spree::Address", optional: true
  alias_attribute :billing_address, :bill_address
  accepts_nested_attributes_for :bill_address

  belongs_to :ship_address, class_name: "Spree::Address", optional: true
  alias_attribute :shipping_address, :ship_address
  accepts_nested_attributes_for :ship_address

  validates :code, uniqueness: { scope: :enterprise_id, allow_nil: true }
  validates :email, presence: true, 'valid_email_2/email': true,
                    uniqueness: {
                      scope: :enterprise_id,
                      message: I18n.t('validation_msg_is_associated_with_an_exising_customer')
                    }

  scope :of, ->(enterprise) { where(enterprise_id: enterprise) }
  scope :managed_by, ->(user) {
    user&.persisted? ? where(user: user).or(of(Enterprise.managed_by(user))) : none
  }
  scope :created_manually, -> { where(created_manually: true) }
  scope :visible, -> { where(id: Spree::Order.complete.select(:customer_id)).or(created_manually) }

  attr_accessor :gateway_recurring_payment_client_secret, :gateway_shop_id

  def full_name
    "#{first_name} #{last_name}".strip
  end

  private

  def downcase_email
    email&.downcase!
  end

  def empty_code
    self.code = nil if code.blank?
  end

  def associate_user
    self.user = user || Spree::User.find_by(email: email)
  end

  def update_orders_and_delete_canceled_subscriptions
    if Subscription.where(customer_id: id).not_canceled.any?
      errors.add(:base, I18n.t('admin.customers.destroy.has_associated_subscriptions'))
      throw :abort
    end
    Subscription.where(customer_id: id).destroy_all
    orders.update_all(customer_id: nil)
  end
end
