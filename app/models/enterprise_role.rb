# frozen_string_literal: true

class EnterpriseRole < ApplicationRecord
  belongs_to :user, class_name: "Spree::User"
  belongs_to :enterprise

  validates :enterprise_id,
            uniqueness: { scope: :user_id, message: I18n.t(:enterprise_role_uniqueness_error) }

  scope :by_user_email, -> { joins(:user).order('spree_users.email ASC') }
end
