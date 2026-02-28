# frozen_string_literal: true

class UserInvitation
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  attribute :enterprise
  attribute :email

  before_validation :normalize_email

  validates :email, presence: true, 'valid_email_2/email': { mx: true }
  validates :enterprise, presence: true
  validate :not_existing_enterprise_user

  def save!
    return unless valid?

    user = find_or_create_user!
    enterprise.users << user

    if user.previously_new_record?
      EnterpriseMailer.manager_invitation(enterprise, user).deliver_later
    end
  end

  private

  def find_or_create_user!
    Spree::User.find_or_create_by!(email: email) do |user|
      user.email = email
      user.password = SecureRandom.base58(64)
      user.unconfirmed_email = email
      user.reset_password_token = Devise.friendly_token
      # Same time as used in Devise's lib/devise/models/recoverable.rb.
      user.reset_password_sent_at = Time.now.utc
    end
  end

  def normalize_email
    self.email = email.strip if email.present?
  end

  def not_existing_enterprise_user
    return unless email.present? && enterprise.users.where(email: email).exists?

    errors.add(:email, :is_already_manager)
  end
end
