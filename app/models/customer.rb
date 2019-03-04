class Customer < ActiveRecord::Base
  acts_as_taggable

  belongs_to :enterprise
  belongs_to :user, class_name: Spree.user_class
  has_many :orders, class_name: Spree::Order
  before_destroy :check_for_orders

  belongs_to :bill_address, foreign_key: :bill_address_id, class_name: Spree::Address
  alias_attribute :billing_address, :bill_address
  accepts_nested_attributes_for :bill_address

  belongs_to :ship_address, foreign_key: :ship_address_id, class_name: Spree::Address
  alias_attribute :shipping_address, :ship_address
  accepts_nested_attributes_for :ship_address

  before_validation :downcase_email
  before_validation :empty_code

  validates :code, uniqueness: { scope: :enterprise_id, allow_nil: true }
  validates :email, presence: true, uniqueness: { scope: :enterprise_id, message: I18n.t('validation_msg_is_associated_with_an_exising_customer') }
  validates :enterprise_id, presence: true

  scope :of, ->(enterprise) { where(enterprise_id: enterprise) }

  before_create :associate_user

  private

  def downcase_email
    email.andand.downcase!
  end

  def empty_code
    self.code = nil if code.blank?
  end

  def associate_user
    self.user = user || Spree::User.find_by_email(email)
  end

  def check_for_orders
    return true unless orders.any?
    errors[:base] << I18n.t('admin.customers.destroy.has_associated_orders')
    false
  end
end
