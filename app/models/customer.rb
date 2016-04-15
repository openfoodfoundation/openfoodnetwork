class Customer < ActiveRecord::Base
  acts_as_taggable

  belongs_to :enterprise
  belongs_to :user, class_name: Spree.user_class

  before_validation :downcase_email

  validates :code, uniqueness: { scope: :enterprise_id, allow_blank: true, allow_nil: true }
  validates :email, presence: true, uniqueness: { scope: :enterprise_id, message: I18n.t('validation_msg_is_associated_with_an_exising_customer') }
  validates :enterprise_id, presence: true

  scope :of, ->(enterprise) { where(enterprise_id: enterprise) }

  before_create :associate_user

  private

  def downcase_email
    email.andand.downcase!
  end

  def associate_user
    self.user = user || Spree::User.find_by_email(email)
  end
end
