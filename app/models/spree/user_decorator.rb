Spree.user_class.class_eval do
  has_many :enterprise_roles, :dependent => :destroy
  has_many :enterprises, through: :enterprise_roles
  has_many :owned_enterprises, class_name: 'Enterprise', foreign_key: :owner_id, inverse_of: :owner
  has_one :cart

  accepts_nested_attributes_for :enterprise_roles, :allow_destroy => true

  attr_accessible :enterprise_ids, :enterprise_roles_attributes, :enterprise_limit
  after_create :send_signup_confirmation

  validate :limit_owned_enterprises

  def known_users
    Spree::User
    .includes(:enterprises)
    .where("enterprises.id IN (SELECT enterprise_id FROM enterprise_roles WHERE user_id = ?)", id)
  end

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

  def can_own_more_enterprises?
    owned_enterprises(:reload).size < enterprise_limit
  end

  private

  def limit_owned_enterprises
    if owned_enterprises.size > enterprise_limit
      errors.add(:owned_enterprises, "^#{email} is not permitted to own any more enterprises (limit is #{enterprise_limit}).")
    end
  end
end
