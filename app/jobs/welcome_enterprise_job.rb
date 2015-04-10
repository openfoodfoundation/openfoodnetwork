WelcomeEnterpriseJob = Struct.new(:enterprise_id) do
  def perform
    enterprise = Enterprise.find enterprise_id
    EnterpriseMailer.welcome(enterprise).deliver
  end
end
