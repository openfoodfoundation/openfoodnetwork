class EnterpriseRole < ActiveRecord::Base
  belongs_to :user, :class_name => Spree.user_class
  belongs_to :enterprise
end
