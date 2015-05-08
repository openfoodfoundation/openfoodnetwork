class Customer < ActiveRecord::Base
  acts_as_taggable

  belongs_to :enterprise
  belongs_to :user, :class_name => Spree.user_class

  validates :code, presence: true, uniqueness: {scope: :enterprise_id}
  validates :email, presence: true
  validates :enterprise_id, presence: true

  scope :of, ->(enterprise) { where(enterprise_id: enterprise) }
end
