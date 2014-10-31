require 'devise/mailers/helpers'
class EnterpriseMailer < Spree::BaseMailer
  include Devise::Mailers::Helpers

  layout 'mailer'

  def confirmation_instructions(record, token, opts={})
    @token = token
    find_enterprise(record)
    opts = {
      subject: "Please confirm your email for #{@enterprise.name}",
      to: [ @enterprise.owner.email, @enterprise.email ].uniq,
      from: from_address,
    }
    devise_mail(record, :confirmation_instructions, opts)
  end

  private
  def find_enterprise(enterprise)
    @enterprise = enterprise.is_a?(Enterprise) ? enterprise : Enterprise.find(enterprise)
  end
end
