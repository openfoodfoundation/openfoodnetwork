Spree.user_class.class_eval do
  has_many :enterprise_roles, :dependent => :destroy
  has_many :enterprises, through: :enterprise_roles
  has_one :cart

  accepts_nested_attributes_for :enterprise_roles, :allow_destroy => true

  attr_accessible :enterprise_ids, :enterprise_roles_attributes
  after_create :send_signup_confirmation

  def build_enterprise_roles
    Enterprise.all.each do |enterprise|
      unless self.enterprise_roles.find_by_enterprise_id enterprise.id
        self.enterprise_roles.build(:enterprise => enterprise)
      end
    end
  end

  def send_signup_confirmation
    Spree::UserMailer.signup_confirmation(self).deliver
  end
end
