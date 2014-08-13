class EnterpriseRole < ActiveRecord::Base
  belongs_to :user, :class_name => Spree.user_class
  belongs_to :enterprise

  scope :by_user_email, joins(:user).order('spree_users.email ASC')
end
