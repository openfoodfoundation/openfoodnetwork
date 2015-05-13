class Customer < ActiveRecord::Base
  acts_as_taggable

  belongs_to :enterprise
  belongs_to :user, :class_name => Spree.user_class

  validates :code, uniqueness: { scope: :enterprise_id, allow_blank: true, allow_nil: true }
  validates :email, presence: true, uniqueness: { scope: :enterprise_id, message: "is associated with an existing customer" }
  validates :enterprise_id, presence: true

  scope :of, ->(enterprise) { where(enterprise_id: enterprise) }

  before_create :associate_user

  private

  def associate_user
    self.user = user || Spree::User.find_by_email(email)
  end
end
