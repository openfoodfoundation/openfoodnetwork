class WelcomeEnterpriseJob < ActiveJob::Base
  def perform(enterprise_id)
    enterprise = Enterprise.find enterprise_id
    EnterpriseMailer.welcome(enterprise).deliver
  end
end
