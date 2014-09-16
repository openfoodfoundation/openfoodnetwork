class EnterpriseMailer < Spree::BaseMailer
  def creation_confirmation(enterprise)
    find_enterprise(enterprise)
    subject = "#{@enterprise.name} is now on #{Spree::Config[:site_name]}"
    mail(:to => @enterprise.owner.email, :from => from_address, :subject => subject)
  end

  private
  def find_enterprise(enterprise)
    @enterprise = enterprise.is_a?(Enterprise) ? enterprise : Enterprise.find(enterprise)
  end
end
