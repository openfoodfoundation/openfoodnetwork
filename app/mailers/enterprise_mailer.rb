require 'devise/mailers/helpers'
class EnterpriseMailer < Spree::BaseMailer
  include Devise::Mailers::Helpers

  def welcome(enterprise)
    @enterprise = enterprise
    subject = t('enterprise_mailer.welcome.subject',
                enterprise: @enterprise.name,
                sitename: Spree::Config[:site_name])
    mail(:to => enterprise.email,
         :from => from_address,
         :subject => subject)
  end

  def confirmation_instructions(record, token)
    @token = token
    find_enterprise(record)
    subject = t('enterprise_mailer.confirmation_instructions.subject',
                enterprise: @enterprise.name)
    mail(to: (@enterprise.unconfirmed_email || @enterprise.email),
         from: from_address,
         subject: subject)
  end

  private

  def find_enterprise(enterprise)
    @enterprise = enterprise.is_a?(Enterprise) ? enterprise : Enterprise.find(enterprise)
  end
end
