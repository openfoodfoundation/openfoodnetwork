class EnterpriseGroup < ActiveRecord::Base
  acts_as_list

  has_and_belongs_to_many :enterprises

  validates :name, presence: true
  validates :description, presence: true

  attr_accessible :name, :description, :long_description, :on_front_page, :enterprise_ids

  attr_accessible :promo_image
  has_attached_file :promo_image, styles: {medium: "800>400"}
  validates_attachment_content_type :promo_image, :content_type => /\Aimage\/.*\Z/

  attr_accessible :logo
  has_attached_file :logo, styles: {medium: "100x100"}
  validates_attachment_content_type :logo, :content_type => /\Aimage\/.*\Z/

  scope :by_position, order('position ASC')
  scope :on_front_page, where(on_front_page: true)
end
