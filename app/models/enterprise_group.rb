class EnterpriseGroup < ActiveRecord::Base
  has_and_belongs_to_many :enterprises

  validates :name, presence: true
end
