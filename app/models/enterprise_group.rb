class EnterpriseGroup < ActiveRecord::Base
  has_and_belongs_to_many :enterprises

  validates :name, presence: true

  scope :on_front_page, where(on_front_page: true)
end
