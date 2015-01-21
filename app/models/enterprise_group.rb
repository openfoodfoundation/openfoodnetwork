class EnterpriseGroup < ActiveRecord::Base
  acts_as_list

  has_and_belongs_to_many :enterprises
  belongs_to :address, :class_name => 'Spree::Address'
  accepts_nested_attributes_for :address
  validates :address, presence: true, associated: true
  before_validation :set_unused_address_fields

  validates :name, presence: true
  validates :description, presence: true

  attr_accessible :name, :description, :long_description, :on_front_page, :enterprise_ids
  attr_accessible :logo, :promo_image

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

  def set_unused_address_fields
    address.firstname = address.lastname = address.phone = 'unused' if address.present?
  end

end
