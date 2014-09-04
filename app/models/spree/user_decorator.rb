Spree.user_class.class_eval do
  has_many :enterprise_roles, :dependent => :destroy
  has_many :enterprises, through: :enterprise_roles
  has_many :owned_enterprises, class_name: 'Enterprise', foreign_key: :owner_id
  has_one :cart

  accepts_nested_attributes_for :enterprise_roles, :allow_destroy => true

  attr_accessible :enterprise_ids, :enterprise_roles_attributes
  after_create :send_signup_confirmation

  validate :owned_enterprises_count

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

  private

  def owned_enterprises_count
    if owned_enterprises.size > enterprise_limit
      errors.add(:owned_enterprises, "^The nominated user is not permitted to own own any more enterprises.")
    end
  end
end
