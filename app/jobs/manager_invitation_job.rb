# frozen_string_literal: true

class ManagerInvitationJob < ActiveJob::Base
  def perform(enterprise_id, user_id)
    enterprise = Enterprise.find enterprise_id
    user = Spree::User.find user_id
    EnterpriseMailer.manager_invitation(enterprise, user).deliver_now
  end
end
