class EnterpriseRole < ActiveRecord::Base
  belongs_to :user, :class_name => Spree.user_class
  belongs_to :enterprise

  validates_presence_of :user_id, :enterprise_id
  validates_uniqueness_of :enterprise_id, scope: :user_id, message: I18n.t(:enterprise_role_uniqueness_error)

  scope :by_user_email, joins(:user).order('spree_users.email ASC')

  def self.receives_notifications_for(enterprise_id)
    manager = EnterpriseRole.find_by_enterprise_id_and_receives_notifications(enterprise_id, true)
    return nil if manager.blank?
    Spree::User.find(manager.user_id)
  end

  def self.set_notification_user(user_id, enterprise_id)
    managers_for(enterprise_id).map do |m|
      if m.user_id == user_id.to_i
        m.update_attributes receives_notifications: true
      elsif m.user_id != user_id.to_i && m.receives_notifications
        m.update_attributes receives_notifications: false
      end
    end
  end

  def self.managers_for(enterprise_id)
    EnterpriseRole.where(enterprise_id: enterprise_id)
  end
end
