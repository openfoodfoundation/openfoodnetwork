require 'devise/mailers/helpers'
class EnterpriseMailer < Spree::BaseMailer
  include Devise::Mailers::Helpers

  def creation_confirmation(enterprise)
    find_enterprise(enterprise)
    subject = "#{@enterprise.name} is now on #{Spree::Config[:site_name]}"
    mail(:to => @enterprise.owner.email, :from => from_address, :subject => subject)
  end

  def confirmation_instructions(record, token, opts={})
    @token = token
    devise_mail(record, :confirmation_instructions, opts)
  end

  private
  def find_enterprise(enterprise)
    @enterprise = enterprise.is_a?(Enterprise) ? enterprise : Enterprise.find(enterprise)
  end
end
