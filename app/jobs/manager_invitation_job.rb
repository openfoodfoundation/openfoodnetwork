ManagerInvitationJob = Struct.new(:enterprise_id, :user_id) do
  def perform
    enterprise = Enterprise.find enterprise_id
    user = Spree::User.find user_id
    EnterpriseMailer.manager_invitation(enterprise, user).deliver
  end
end
