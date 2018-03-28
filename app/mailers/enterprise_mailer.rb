require 'devise/mailers/helpers'
class EnterpriseMailer < Spree::BaseMailer
  include Devise::Mailers::Helpers

  def welcome(enterprise)
    @enterprise = enterprise
    subject = t('enterprise_mailer.welcome.subject',
                enterprise: @enterprise.name,
                sitename: Spree::Config[:site_name])
    mail(:to => enterprise.contact.email,
         :from => from_address,
         :subject => subject)
  end

  def manager_invitation(enterprise, user)
    @enterprise = enterprise
    @instance = Spree::Config[:site_name]
    @instance_email = from_address

    subject = t('enterprise_mailer.invite_manager.subject', enterprise: @enterprise.name)

    mail(to: user.email,
         from: from_address,
         subject: subject)
  end

  private

  def find_enterprise(enterprise)
    @enterprise = enterprise.is_a?(Enterprise) ? enterprise : Enterprise.find(enterprise)
  end
end
