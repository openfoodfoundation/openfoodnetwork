class EnterpriseGroup < ActiveRecord::Base
  acts_as_list

  has_and_belongs_to_many :enterprises

  validates :name, presence: true

  scope :by_position, order('position ASC')
  scope :on_front_page, where(on_front_page: true)
end
