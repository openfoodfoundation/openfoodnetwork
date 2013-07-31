Spree.user_class.class_eval do
  has_many :enterprise_roles, :dependent => :destroy
  has_many :enterprises, through: :enterprise_roles
end
