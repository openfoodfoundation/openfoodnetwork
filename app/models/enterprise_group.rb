require 'open_food_network/locking'
require 'open_food_network/permalink_generator'
require 'spree/core/s3_support'

class EnterpriseGroup < ActiveRecord::Base
  include PermalinkGenerator
  acts_as_list

  has_and_belongs_to_many :enterprises, join_table: 'enterprise_groups_enterprises'
  belongs_to :owner, class_name: 'Spree::User', foreign_key: :owner_id, inverse_of: :owned_groups
  belongs_to :address, class_name: 'Spree::Address'
  accepts_nested_attributes_for :address
  validates :address, presence: true, associated: true
  before_validation :set_undefined_address_fields
  before_validation :set_unused_address_fields
  after_find :unset_undefined_address_fields
  after_save :unset_undefined_address_fields

  validates :name, presence: true
  validates :description, presence: true

  before_validation :sanitize_permalink
  validates :permalink, uniqueness: true, presence: true

  delegate :phone, :address1, :address2, :city, :zipcode, :state, :country, to: :address

  has_attached_file :logo,
                    styles: { medium: "100x100" },
                    url: '/images/enterprise_groups/logos/:id/:style/:basename.:extension',
                    path: 'public/images/enterprise_groups/logos/:id/:style/:basename.:extension'

  has_attached_file :promo_image,
                    styles: { large: ["1200x260#", :jpg] },
                    url: '/images/enterprise_groups/promo_images/:id/:style/:basename.:extension',
                    path: 'public/images/enterprise_groups/promo_images/:id/:style/:basename.:extension'

  validates_attachment_content_type :logo, content_type: %r{\Aimage/.*\Z}
  validates_attachment_content_type :promo_image, content_type: %r{\Aimage/.*\Z}

  include Spree::Core::S3Support
  supports_s3 :logo
  supports_s3 :promo_image

  scope :by_position, -> { order('position ASC') }
  scope :on_front_page, -> { where(on_front_page: true) }
  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      where(nil)
    else
      where('owner_id = ?', user.id)
    end
  }

  def set_unused_address_fields
    address.firstname = address.lastname = I18n.t(:unused)
  end

  def set_undefined_address_fields
    address.phone.present? || address.phone = I18n.t(:undefined)
    address.address1.present? || address.address1 = I18n.t(:undefined)
    address.city.present? || address.city = I18n.t(:undefined)
    address.state.present? || address.state = address.country.states.first
    address.zipcode.present? || address.zipcode = I18n.t(:undefined)
  end

  def unset_undefined_address_fields
    return if address.blank?

    address.phone.sub!(/^#{I18n.t(:undefined)}$/, '')
    address.address1.sub!(/^#{I18n.t(:undefined)}$/, '')
    address.city.sub!(/^#{I18n.t(:undefined)}$/, '')
    address.zipcode.sub!(/^#{I18n.t(:undefined)}$/, '')
  end

  def to_param
    permalink
  end

  private

  def sanitize_permalink
    if permalink.blank? || permalink_changed?
      requested = permalink.presence || permalink_was.presence || name.presence || 'group'
      self.permalink = create_unique_permalink(requested.parameterize)
    end
  end
end
