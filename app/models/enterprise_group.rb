# frozen_string_literal: true

require 'open_food_network/locking'

class EnterpriseGroup < ApplicationRecord
  include PermalinkGenerator

  self.ignored_columns = %i(logo_file_name
                            logo_content_type
                            logo_file_size
                            logo_updated_at
                            promo_image_file_name
                            promo_image_content_type
                            promo_image_file_size
                            promo_image_updated_at)

  acts_as_list

  has_and_belongs_to_many :enterprises, join_table: 'enterprise_groups_enterprises'
  belongs_to :owner, class_name: 'Spree::User', inverse_of: :owned_groups
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

  has_one_attached :logo
  has_one_attached :promo_image

  validates :logo, processable_image: true, content_type: %r{\Aimage/(png|jpeg|gif|jpg|svg\+xml|webp)\Z} # added processable_image: true,
  validates :promo_image, processable_image: true, content_type: %r{\Aimage/(png|jpeg|gif|jpg|svg\+xml|webp)\Z} # added processable_image: true

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
    address.firstname = address.lastname = address.company = I18n.t(:unused)
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

    address.phone = address.phone.sub(/^#{I18n.t(:undefined)}$/, '')
    address.address1 = address.address1.sub(/^#{I18n.t(:undefined)}$/, '')
    address.city = address.city.sub(/^#{I18n.t(:undefined)}$/, '')
    address.zipcode = address.zipcode.sub(/^#{I18n.t(:undefined)}$/, '')
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
