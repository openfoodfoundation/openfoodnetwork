require 'open_food_network/locking'

class EnterpriseGroup < ActiveRecord::Base
  acts_as_list

  has_and_belongs_to_many :enterprises
  belongs_to :owner, class_name: 'Spree::User', foreign_key: :owner_id, inverse_of: :owned_groups
  belongs_to :address, :class_name => 'Spree::Address'
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

  attr_accessible :name, :description, :long_description, :on_front_page, :enterprise_ids
  attr_accessible :owner_id
  attr_accessible :permalink
  attr_accessible :logo, :promo_image
  attr_accessible :address_attributes
  attr_accessible :email, :website, :facebook, :instagram, :linkedin, :twitter

  delegate :phone, :address1, :address2, :city, :zipcode, :state, :country, :to => :address

  has_attached_file :logo,
    styles: {medium: "100x100"},
    url:  '/images/enterprise_groups/logos/:id/:style/:basename.:extension',
    path: 'public/images/enterprise_groups/logos/:id/:style/:basename.:extension'

  has_attached_file :promo_image,
    styles: {large: ["1200x260#", :jpg]},
    url:  '/images/enterprise_groups/promo_images/:id/:style/:basename.:extension',
    path: 'public/images/enterprise_groups/promo_images/:id/:style/:basename.:extension'

  validates_attachment_content_type :logo, :content_type => /\Aimage\/.*\Z/
  validates_attachment_content_type :promo_image, :content_type => /\Aimage\/.*\Z/

  include Spree::Core::S3Support
  supports_s3 :logo
  supports_s3 :promo_image

  scope :by_position, order('position ASC')
  scope :on_front_page, where(on_front_page: true)
  scope :managed_by, lambda { |user|
    if user.has_spree_role?('admin')
      scoped
    else
      where('owner_id = ?', user.id)
    end
  }

  def set_unused_address_fields
    address.firstname = address.lastname = 'unused' if address.present?
  end

  def set_undefined_address_fields
    return unless address.present?
    address.phone.present? || address.phone = 'undefined'
    address.address1.present? || address.address1 = 'undefined'
    address.city.present? || address.city = 'undefined'
    address.zipcode.present? || address.zipcode = 'undefined'
  end

  def unset_undefined_address_fields
    return unless address.present?
    address.phone.sub!(/^undefined$/, '')
    address.address1.sub!(/^undefined$/, '')
    address.city.sub!(/^undefined$/, '')
    address.zipcode.sub!(/^undefined$/, '')
  end

  def to_param
    permalink
  end

  private

  def self.find_available_value(existing, requested)
    return requested unless existing.include?(requested)
    used_indices = existing.map do |p|
      p.slice!(/^#{requested}/)
      p.match(/^\d+$/).to_s.to_i
    end
    options = (1..used_indices.length + 1).to_a - used_indices
    requested + options.first.to_s
  end

  def find_available_permalink(requested)
    existing = self.class.where(id: !id).where("permalink LIKE ?", "#{requested}%").pluck(:permalink)
    self.class.find_available_value(existing, requested)
  end

  def sanitize_permalink
    if permalink.blank? || permalink_changed?
      requested = permalink.presence || permalink_was.presence || name.presence || 'group'
      self.permalink = find_available_permalink(requested.parameterize)
    end
  end
end
